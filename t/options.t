#! /usr/bin/perl
#
#===============================================================================
#
#         FILE:  options.t
#
#  DESCRIPTION:  Test variations in output that result from command-line options
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach, <geoff@hughes.net>
#      VERSION:  1.0
#      CREATED:  10/16/07 14:46:57 PDT
#     REVISION:  ---
#
#===============================================================================

use 5.006002;

use strict;
use warnings;

use lib qw(./t);
use Run qw(run );
use Pod::HtmlEasy::Data qw(NL body);
use version; our $VERSION = qv('1.0'); # Also appears in "=head1 VERSION" in the POD below

#--------------------------- test 4

run( q{Empty POD file}, undef, [], [], );

#--------------------------- test 5

my $outfile = q{./test.html};
run(q{Output to file},

    # Null pod file => =pod/=cut
    [],
    [],
    [],
    {   outfile      => $outfile,
        title        => $outfile,
        no_css       => 1,
        no_index     => 1,
        no_generator => 1,
    },
);

#--------------------------- test 6

run(q{Generator HTML},
    [],
    [],
    [],
    {   no_css   => 1,
        no_index => 1,
    },
);

#--------------------------- test 7

run(q{Index prototype},
    [],
    [],
    [],
    {

        no_css       => 1,
        no_generator => 1,
    },
);

#--------------------------- test 8

run(q{User-specified index},
    [],
    [],
    [ q{foo => bar}, ],
    {   index        => q{foo => bar},
        no_css       => 1,
        no_generator => 1,
    },
);

#--------------------------- test 9

run(q{Standard CSS},
    [],
    [],
    [],
    {   no_index     => 1,
        no_generator => 1,
    },
);

#--------------------------- test 10

run(q{CSS from file},
    [],
    [],
    [],
    {

        # Specify a file for the css. We're only testing the HTML output,
        # so there's no actual file, in case you're checking the rendering.
        css          => q{test.css},
        no_index     => 1,
        no_generator => 1,
    },
);

#--------------------------- test 11

my $test_css = << "TEST_CSS";
BODY {
  background: blue;
  color: black;
  font-family: arial,sans-serif;
  margin: 0;
  padding: 1ex;
}
TEST_CSS

run(q{CSS from option},
    [],
    [],
    [],
    {

        # Specify stuff for css
        css          => qq{$test_css},
        no_index     => 1,
        no_generator => 1,
    },
);

#--------------------------- test 12

run(q{Default <body>},
    [],
    [],
    [],
    {   no_css       => 1,
        no_index     => 1,
        no_generator => 1,
    },
);

#--------------------------- test 13

run(q{Custom <body>, single change},
    [],
    [],
    [],
    {   no_css       => 1,
        no_index     => 1,
        no_generator => 1,
        body         => { alink => '#XXXXXX' },
    },
);

#--------------------------- test 14

my $body = q{alink="#AAAAAA" bgcolor="#BBBBBB" link="#CCCCCC" }
    . q{text="#DDDDDD" vlink="#EEEEEE"};
run(q{Custom <body>, multiple changes},
    [],
    [],
    [],
    {   no_css       => 1,
        no_index     => 1,
        no_generator => 1,
        body         => $body,
    },
);

#--------------------------- test 15

run(q{Testing TOP literal option},
    [ q{=head1 NAME Testing TOP literal option}, ],
    [         q{<h1><a href='#_top'} 
            . NL
            . q{title='click to go to top of document'}
            . NL
            . q{name='NAMETestingTOPliteraloption'>NAME Testing }
            . q{TOP literal option&Z;</a></h1>},
    ],
    [         q{<li><a href='#NAMETestingTOPliteraloption'>NAME Testing }
            . q{TOP literal option</a></li>},
    ],
    {   title        => q{Testing TOP literal option},
        no_css       => 1,
        no_generator => 1,
        top          => q{Z},
    },
);

#--------------------------- test 16

my $top_file = q{top.jpg};
system qq{touch $top_file};
run(q{Testing TOP file option},
    [ q{=head1 NAME Testing TOP file option}, ],
    [         q{<h1><a href='#_top'} 
            . NL
            . q{title='click to go to top of document'}
            . NL
            . q{name='NAMETestingTOPfileoption'>NAME Testing TOP file option}
            . qq{<img src='$top_file'}
            . NL
            . q{alt=&uArr;></a></h1>},
    ],
    [   q{<li><a href='#NAMETestingTOPfileoption'>NAME Testing TOP file option</a></li>},
    ],
    {   title        => q{Testing TOP file option},
        no_css       => 1,
        no_generator => 1,
        top          => q{top.jpg},
    },
);
unlink $top_file;

#--------------------------- test 17

run(q{Verify index_item},
    [   q{=head1 NAME Verify index_item},
        q{=head2 Verify head2 level},
        q{=item Item 1},
        q{This is item 1},
        q{=item Item 2},
        q{This is item 2},
        q{=item *},
        q{Starred item},
        q{=item * title star},
        q{Title starred item},
        q{=head2 Verify head2 new level},
    ],
    [   q{<a name='NAMEVerifyindex_item'></a><h1>NAME Verify index_item</h1>},
        q{<a name='Verifyhead2level'></a><h2>Verify head2 level</h2>},
        q{<li><a name='Item1'></a>Item 1</li>},
        q{<p>This is item 1</p>},
        q{<li><a name='Item2'></a>Item 2</li>},
        q{<p>This is item 2</p>},
        q{<li><a name='Starreditem'></a>Starred item</li>},
        q{<li><a name='titlestar'></a>title star</li>},
        q{<p>Title starred item</p>},
        q{<a name='Verifyhead2newlevel'></a><h2>Verify head2 new level</h2>},
    ],
    [   q{<li><a href='#NAMEVerifyindex_item'>NAME Verify index_item</a></li>},
        q{<ul>},
        q{<li><a href='#Verifyhead2level'>Verify head2 level</a></li>},
        q{<ul>},
        q{<li><a href='#Item1'>Item 1</a></li>},
        q{<li><a href='#Item2'>Item 2</a></li>},
        q{<li><a href='#titlestar'>title star</a></li>},
        q{</ul>},
        q{<li><a href='#Verifyhead2newlevel'>Verify head2 new level</a></li>},
        q{</ul>},
    ],
    {   title        => q{Verify index_item},
        no_css       => 1,
        index_item   => 1,
        no_generator => 1,
    },
);

#--------------------------- test 18

run( q{Testing only_content}, [], [], [], { only_content => 1, }, );

#--------------------------- test 19

my $htmleasy = Pod::HtmlEasy->new(
    on_G => sub {
        my ( $this, $txt ) = @_;
        return "<img src='$txt' border=0>";
    },
);

run(q{User formatting command},
    [

        # It's not an error if this file is missing,
        # which it is, in this case
        q{G<./graphic-file.jpg>},
    ],
    [ q{<p><img src='./graphic-file.jpg' border=0></p>}, ],
    [],
    {   htmleasy     => $htmleasy,
        no_css       => 1,
        no_generator => 1,
    }
);
