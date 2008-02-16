#! /usr/bin/perl
#
#===============================================================================
#
#         FILE:  bugs.t
#
#  DESCRIPTION:  Codings that caused problems in the past, but no more :-)
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach, <geoff@hughes.net>
#      VERSION:  1.0
#      CREATED:  12/19/07 13:45:55 PST
#     REVISION:  ---
#===============================================================================

use 5.006002;

use strict;
use warnings;

use lib qw(./t);
use Run qw( run );
use Pod::HtmlEasy::Data qw( NL );
use version; our $VERSION = qv('1.0');

#--------------------------- test 4

run(q{URL in verbatum text},
    [   q{=item URL in verbatum text},
        q{Leading non-verbatum},
        q{    http://www.somewhere.com},
        q{trailing non-verbatum},
    ],
    [   q{<li><a name='URLinverbatumtext'></a>URL in verbatum text</li>},
        q{<p>Leading non-verbatum</p>},
        q{<pre>    <a href='http://www.somewhere.com' }
            . q{target='_blank'>www.somewhere.com</a></pre>},
        q{<p>trailing non-verbatum</p>},
    ],
);

#--------------------------- test 5

run(q{Multiple MARK_FILTER IDs},
    [

        # Example of how to handle multi-line paragraphs
        q{=item Multiple MARK_FILTER IDs},
        q{The following used to confuse due to multiple MARK_FILTER instances }
            . q{with the same ID.},
        q{},
        q{Remember that if the connection is }
            . q{C<L<E<gt>keepalive|docs::2.0::api::Apache2::Connection/C_keepalive_>> }
            . q{and the connection filter is removed, it won't be added until the }
            . q{connection is closed. Which may happen after many HTTP requests. You }
            . q{may want to keep the filter in place and pass the data through }
            . q{unmodified, by returning C<Apache2::Const::DECLINED>. }
            . q{If you need to reset the }
            . q{whole or parts of the filter context between requests, use the }
            . q{L<technique based on C<$c-E<gt>keepalives> counting|}
            . q{docs::2.0::user::handler::filters>.},
    ],
    [   q{<li><a name='MultipleMARK_FILTERIDs'></a>}
            . q{Multiple MARK_FILTER IDs</li>},
        q{<p>The following used to confuse due to multiple MARK_FILTER instances }
            . q{with the same ID.</p>},
        q{<p>Remember that if the connection is }
            . q{<font face='Courier New'><i><a href='http://search.cpan.org/perldoc?}
            . q{docs::2.0::api::Apache2::Connection#C_keepalive_'>}
            . q{&gt;keepalive</a></i></font> }
            . q{and the connection filter is removed, it won't be added until the }
            . q{connection is closed. Which may happen after many HTTP requests. You }
            . q{may want to keep the filter in place and pass the data through }
            . q{unmodified, by returning <font face='Courier New'>}
            . q{Apache2::Const::DECLINED</font>. }
            . q{If you need to reset the }
            . q{whole or parts of the filter context between requests, use the }
            . q{<i><a href='http://search.cpan.org/perldoc?}
            . q{docs::2.0::user::handler::filters'>technique }
            . q{based on <font face='Courier New'>}
            . q{$c-&gt;keepalives</font> counting</a></i>.</p>},
    ],
);

#--------------------------- test 6

run(q{Trailing verbatim},
    [ q{=item Trailing verbatim}, q{    This used to be ignored.}, ],
    [   q{<li><a name='Trailingverbatim'></a>Trailing verbatim</li>},
        q{<pre>    This used to be ignored.</pre>},
    ],
);

#--------------------------- test 7

run(q{Unsupported URIs},
    [   q{=item Unsupported URIs},
        q{L<fax:+358.555.1234567>},
        q{L<tel:+358-555-1234567>},
        q{L<modem:+3585551234567;type=v32b?7e1;type=v110 >},
        q{L<tel:0w003585551234567;phone-context=+3585551234>},
        q{L<tel:+1234567890;phone-context=+1234;vnd.company.option=foo>},
    ],
    [   q{<li><a name='UnsupportedURIs'></a>Unsupported URIs</li>},
        q{<p>fax:+358.555.1234567</p>},
        q{<p>tel:+358-555-1234567</p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?modem:+3585551234567;}
            . q{type=v32b?7e1;type=v110'>modem:+3585551234567;type=v32b?7e1;}
            . q{type=v110</a></i></p>},
        q{<p>tel:0w003585551234567;phone-context=+3585551234</p>},
        q{<p>tel:+1234567890;phone-context=+1234;vnd.company.option=foo</p>},
    ],
);

#--------------------------- test 8

run(q{Special cases of verbatim},
    [   q{=item Special cases of verbatim},
        q{=item C<< $thing->stuff(I<dodad>) >>)},
        q{ That's what I<you> think!} 
            . NL
            . q{ What's C<dump()> for?}
            . NL
            . q{ X<C<chmod> and C<unlink()> Under Different Operating Systems>}
            . NL
            . q{ C<thing> }
            . NL
            . q{ C<< thing >> }
            . NL
            . q{ C<<           thing     >> }
            . NL
            . q{ C<<<   thing >>> }
            . NL
            . q{ C<<<< }
            . NL
            . q{ thing }
            . NL
            . q{        >>>> },
    ],
    [   q{<li><a name='Specialcasesofverbatim'></a>}
            . q{Special cases of verbatim</li>},
        q{<li><a name='$thing->stuff(dodad))'></a><font face='Courier New'>}
            . q{$thing->stuff(<i>dodad</i>)</font>)</li>},
        q{<pre> That's what I&lt;you&gt; think!} 
            . NL
            . q{ What's C&lt;dump()&gt; for?}
            . NL
            . q{ X&lt;C&lt;chmod&gt; and C&lt;unlink()&gt; }
            . q{Under Different Operating Systems&gt;}
            . NL
            . q{ C&lt;thing&gt; }
            . NL
            . q{ C&lt;&lt; thing &gt;&gt; }
            . NL
            . q{ C&lt;&lt;           thing     &gt;&gt; }
            . NL
            . q{ C&lt;&lt;&lt;   thing &gt;&gt;&gt; }
            . NL
            . q{ C&lt;&lt;&lt;&lt; }
            . NL
            . q{ thing }
            . NL
            . q{        &gt;&gt;&gt;&gt; </pre>},
    ],
);

#--------------------------- test 9

run(q{on_S improper call},
    [   q{=item on_S improper call},
        q{The C<:ATTR> marker can also be given a number of options which automate }
            . NL
            . q{other attribute-related behaviours. Each of these options consists of a }
            . NL
            . q{key/value pair, which may be specified in either Perl 5 "fat comma" syntax }
            . NL
            . q{( C<< S<< key => 'value' >> >> ) or in one of the Perl 6 option syntaxes }
            . NL
            . q{( C<< S<< :key<value> >> >> or C<< S<< :key('value') >> >> or  }
            . NL
            . q{C<< S<< :key«value» >> >>).},
    ],
    [

        # Note no extra space at the line ends
        q{<li><a name='on_Simpropercall'></a>on_S improper call</li>},
              q{<p>The <font face='Courier New'>:ATTR</font> marker can also }
            . q{be given a number of options which automate}
            . NL
            . q{other attribute-related behaviours. Each of these options consists of a}
            . NL
            . q{key/value pair, which may be specified in either Perl 5 }
            . q{&quot;fat comma&quot; syntax}
            . NL
            . q{( <font face='Courier New'>key => 'value'</font> ) }
            . q{or in one of the Perl 6 option syntaxes}
            . NL
            . q{( <font face='Courier New'>:key<value></font> or }
            . q{<font face='Courier New'>:key('value')</font> or}
            . NL
            . q{<font face='Courier New'>:key«value»</font>).</p>},
    ],
);

#--------------------------- test 10

run(q{Apache2 unusual content},
    [   q{=head1 NAME},
        q{},
        q{Apache2::Filter & Extra Stuff},
        q{},
        q{},
        q{This is the NAME content, with extra blank lines.} 
            . NL
            . q{The '&' caused problems.},
    ],
    [   q{<a name='NAME'></a><h1>NAME</h1>},
        q{<p>Apache2::Filter &amp; Extra Stuff</p>},
        q{<p>This is the NAME content, with extra blank lines.} 
            . NL
            . q{The '&amp;' caused problems.</p>},
    ],
    [ q{<li><a href='#NAME'>NAME</a></li>}, ],
    {   title        => q{Apache2::Filter & Extra Stuff},
        no_css       => 1,
        no_generator => 1,
    },
);

#--------------------------- test 11

run(q{Indexed item with tabs},
    [ q{=item testing     testing}, q{This is the item}, ],
    [   q{<li><a name='testingtesting'></a>testing     testing</li>},
        q{<p>This is the item</p>},
    ],
    [   q{<ul>},
        q{<li><a href='#testingtesting'>testing     testing</a></li>},
        q{</ul>},
    ],
    {   title        => q{Indexed item with tabs},
        no_css       => 1,
        index_item   => 1,
        no_generator => 1,
    },
);

#--------------------------- test 12

# Workaround for "dispute" between Regexp::Common and Spamassassin PODs
run(q{URL with embedded %2E},
    [ q{http://spamassassin.apache%2Eorg/}, ],
    [         q{<p><a href='http://spamassassin.apache.org/' target='_blank'>}
            . q{spamassassin.apache.org</a></p>}
    ],
);

1;

#--------------------------- test 13

run(q{L<> embedded reference},
    [   q{We're searching for L<this reference> somewhere else.},
        q{=head1 this reference},
    ],
    [   q{<p>We're searching for <i><a href='#thisreference'>"this reference"</a></i> }
            . q{somewhere else.</p>},
        q{<a name='thisreference'></a><h1>this reference</h1>},
    ],
    [ q{<li><a href='#thisreference'>this reference</a></li>}, ],
    {   no_css       => 1,
        index_item   => 1,
        no_generator => 1,
    },
);

#--------------------------- test 14

run(q{L<>, http in =item},
    [ q{=item L<http://www.xxx.bar.com>}, q{=item http://www.foo.bar.com}, ],
    [   q{<li><a name='www.xxx.bar.com'></a>}
            . q{<a href='http://www.xxx.bar.com' target='_blank'>www.xxx.bar.com</a></li>},
        q{<li><a name='www.foo.bar.com'></a>}
            . q{<a href='http://www.foo.bar.com' target='_blank'>www.foo.bar.com</a></li>},
    ],
    [

        # Extra <ul> because we don't have an =head1
        q{<ul>},
        q{<li><a href='#www.xxx.bar.com'>www.xxx.bar.com</a></li>},
        q{<li><a href='#www.foo.bar.com'>www.foo.bar.com</a></li>},
        q{</ul>},
    ],
    {   no_css       => 1,
        index_item   => 1,
        no_generator => 1,
    },
);

#--------------------------- test 15

run(q{Empty L<>: error message is normal},
    [ q{This is very bad: L<> ... or is it?}, ],
    [   q{<!-- POD_ERROR: Empty L<> -->},
        q{<p>This is very bad:  ... or is it?</p>},
    ],
    undef,
);

__END__

=cut

# Write to file for testing
#
use lib qw(./t);
use Run qw( run );
use Pod::HtmlEasy::Data qw( NL );
$ENV{DUMPHTML} = 1;

# 16 lines from this point

#--------------------------- test 13

run ( 
        q{},
        [
            q{},
        ],
        [ or undef,
        ],
        [ or undef,
        ],
        {
        },
    );

