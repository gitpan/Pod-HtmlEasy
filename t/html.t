#! /usr/bin/perl
#
#===============================================================================
#
#         FILE:  html.t
#
#  DESCRIPTION:  Tests of HTML generation from various POD constructs
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach, <geoff@hughes.net>
#      VERSION:  1.0
#      CREATED:  10/28/07 09:56:16 PDT
#     REVISION:  ---
#===============================================================================

use 5.006002;

use strict;
use warnings;

use lib qw(./t);
use Run qw( run html_file );
use Pod::HtmlEasy::Data qw(NL);
use version; our $VERSION = qv('1.0');

#--------------------------- test 4

my $html_file = html_file();

run(q{head1},
    [   q{=head1 Testing POD},
        q{`twas brillig and the slythe toes} 
            . NL
            . q{did gyre and gimbal in the wave},
        qq{=head1 NAME $html_file},
        qq{Content of NAME: note the file is called $html_file},
        q{=head1 E<lt>},
        q{This is the content of a paragraph with less-than as title, ie., E<lt>},
    ],
    [   q{<a name='TestingPOD'></a><h1>Testing POD</h1>},
        q{<p>`twas brillig and the slythe toes} 
            . NL
            . q{did gyre and gimbal in the wave</p>},
        qq{<a name='NAME$html_file'></a><h1>NAME $html_file</h1>},
        qq{<p>Content of NAME: note the file is called $html_file</p>},
        q{<a name='&lt;'></a><h1>&lt;</h1>},
        q{<p>This is the content of a paragraph with less-than as title, ie., &lt;</p>},
    ],
    [   q{<li><a href='#TestingPOD'>Testing POD</a></li>},
        qq{<li><a href='#NAME$html_file'>NAME $html_file</a></li>},
        q{<li><a href='#&lt;'>&lt;</a></li>},
    ],
);

#--------------------------- test 5

run(q{head2},
    [   q{=head2 Testing head2},
        q{`twas brillig and the slythe toes} 
            . NL
            . q{did gyre and gimbal in the wave},
        q{=head2 NAME I<foobar>},
        q{Content of NAME with italicized content I<foobar>} 
            . NL
            . q{and code content C<this is foo bar!>}
            . NL
            . q{This is head 2, so no title effect},
    ],
    [   q{<a name='Testinghead2'></a><h2>Testing head2</h2>},
        q{<p>`twas brillig and the slythe toes} 
            . NL
            . q{did gyre and gimbal in the wave</p>},
        q{<a name='NAMEfoobar'></a><h2>NAME <i>foobar</i></h2>},
        q{<p>Content of NAME with italicized content <i>foobar</i>} 
            . NL
            . q{and code content <font face='Courier New'>this is foo bar!</font>}
            . NL
            . q{This is head 2, so no title effect</p>},
    ],
    [   q{<ul>},
        q{<li><a href='#Testinghead2'>Testing head2</a></li>},
        q{<li><a href='#NAMEfoobar'>NAME <i>foobar</i></a></li>}, q{</ul>},
    ],
);

#--------------------------- test 6

run(q{head3},
    [   q{=head3 Testing head3},
        q{`twas brillig and the slythe toes} 
            . NL
            . q{did gyre and gimbal in the wave},
    ],
    [   q{<a name='Testinghead3'></a><h3>Testing head3</h3>},
        q{<p>`twas brillig and the slythe toes} 
            . NL
            . q{did gyre and gimbal in the wave</p>},
    ],
    [   q{<ul>}, q{<ul>},
        q{<li><a href='#Testinghead3'>Testing head3</a></li>},
        q{</ul>}, q{</ul>},
    ],
);

#--------------------------- test 7

run(q{head4},
    [   q{=head4 Testing head4},
        q{`twas brillig and the slythe toes} 
            . NL
            . q{did gyre and gimbal in the wave},
    ],
    [   q{<a name='Testinghead4'></a><h4>Testing head4</h4>},
        q{<p>`twas brillig and the slythe toes} 
            . NL
            . q{did gyre and gimbal in the wave</p>},
    ],
    [   q{<ul>}, q{<ul>}, q{<ul>},
        q{<li><a href='#Testinghead4'>Testing head4</a></li>},
        q{</ul>}, q{</ul>}, q{</ul>},
    ],
);

#--------------------------- test 8

run(q{item},
    [   q{=item Testing item and verbatum text},
        q{ This text is indened one space} . NL . q{ which makes it verbatum},
        q{=item *},
        q{Starred},
        q{The title of this item is "Starred" because it's "=item *"},
        q{=item * Title on item line},
        q{This item has a normal title and a asterisk, which is ignored}
    ],
    [   q{<li><a name='Testingitemandverbatumtext'></a>}
            . q{Testing item and verbatum text</li>},
        q{<pre> This text is indened one space} 
            . NL
            . q{ which makes it verbatum</pre>},
        q{<li><a name='Starred'></a>Starred</li>},
        q{<p>The title of this item is &quot;Starred&quot; because }
            . q{it's &quot;=item *&quot;</p>},
        q{<li><a name='Titleonitemline'></a>Title on item line</li>},
        q{<p>This item has a normal title and a asterisk, which is ignored</p>},
    ],
);

#--------------------------- test 9

run(q{over and back},
    [   q{=item over 4},
        q{=over 4},
        q{Text that is indented 4 spaces},
        q{=over 10},
        q{"Over 10" text that is indented 4 more spaces, demonstrating that }
            . q{the level is ignored},
        q{=back},
        q{=back},
    ],
    [   q{<li><a name='over4'></a>over 4</li>},
        q{<ul>},
        q{<p>Text that is indented 4 spaces</p>},
        q{<ul>},
        q{<p>&quot;Over 10&quot; text that is indented 4 more spaces, }
            . q{demonstrating that the level is ignored</p>},
        q{</ul>},
        q{</ul>},
    ],
);

#--------------------------- test 10

run(q{ignored controls},
    [   q{=for}, q{=begin}, q{This text is ignored: begin/end group}, q{=end},
    ],
    [    # It's no accident that there's nothing here
    ],
);

#--------------------------- test 11

run(q{various URIs},
    [   q{http://fedoraproject.org/}, q{https://fedoraproject.org/},
        q{ftp://fedoraproject.org/},  q{file:///etc/hosts/},
        q{root@fedoraproject.org},
    ],
    [   q{<p><a href='http://fedoraproject.org/' target='_blank'>}
            . q{fedoraproject.org</a></p>},
        q{<p><a href='https://fedoraproject.org/' target='_blank'>}
            . q{fedoraproject.org</a></p>},
        q{<p><a href='ftp://fedoraproject.org/'>fedoraproject.org</a></p>},
        q{<p><a href='file:///etc/hosts/'>/etc/hosts/</a></p>},
        q{<p><a href='mailto:root@fedoraproject.org'>root@fedoraproject.org</a></p>},
    ],
);

#--------------------------- test 12

run(q{various L<>},
    [   q{L<http://fedoraproject.org/>},
        q{L<https://fedoraproject.org/>},
        q{L<ftp://fedoraproject.org/>},
        q{L<file:///etc/hosts/>},
        q{L<mailto://root@fedoraproject.org>},

        # Pod::Parselinrk sees this as POD spec
        # Quite properly, as its _not_ a hyperlink. See perlpod()
        #q{L<root@fedoraproject.org>},
        q{L<Pod::HtmlEasy>},
        q{L<crontab(5)>},

        # These are from podspec
        q{L<Perlport's section on NL's|perlport/Newlines>},
        q{L<perlport/Newlines>},
        q{L</Object Attributes>},
        q{L<crontab(5)/"DESCRIPTION">},

        # More
        q{L<"Section">},
        q{mail foo@foo.com},
        q{B<L<http://www.foo.com> (foo site).>},
        q{L<Text|Foo::Bar/"sect">},
        q{L<Foo|Foo::Bar>},
        q{L<Foo::Bar>},

        # From parselink.t
        q{L<parselink>},
        q{L<Foo|Bar>},
        q{L<Foo/Bar>},
        q{L<foo/"baz boo">},
        q{L</bar>},
        q{L</"baz boo">},
        q{L</baz boo>},
        q{L<foo bar/baz boo>},
        q{L<fooZ<>bar>},
        qq{L<foo\nbar\nbaz\n/\nboo>},
        q{L<anchor|name/section>},
        q{L<Testing I<italics>|foo/bar>},
        q{L<some manual page|perl(1)>},
        q{L<Nested L<http://www.perl.org/>|fooE<sol>bar>},
        q{L<ls(1)>},

        # An interesting case. The news: gets it as a URL,
        # but as firefox does not support the news protocol,
        # we punt to mail.
        q{L<news:yld72axzc8.fsf@windlord.stanford.edu>},
    ],
    [   q{<p><a href='http://fedoraproject.org/' target='_blank'>}
            . q{fedoraproject.org</a></p>},
        q{<p><a href='https://fedoraproject.org/' target='_blank'>}
            . q{fedoraproject.org</a></p>},
        q{<p><a href='ftp://fedoraproject.org/'>fedoraproject.org</a></p>},
        q{<p><a href='file:///etc/hosts/'>/etc/hosts/</a></p>},
        q{<p><a href='mailto:root@fedoraproject.org'>root@fedoraproject.org</a></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?Pod::HtmlEasy'>Pod::HtmlEasy}
            . q{</a></i></p>},
        q{<p><i>crontab(5)</i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?perlport#Newlines'>Perlport's}
            . q{ section on NL's</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?perlport#Newlines'>"Newlines" }
            . q{in perlport</a></i></p>},
        q{<p><i><a href='#ObjectAttributes'>"Object Attributes"</a></i></p>},
        q{<p><i>"DESCRIPTION" in crontab(5)</i></p>},
        q{<p><i><a href='#Section'>"Section"</a></i></p>},
        q{<p>mail <a href='mailto:foo@foo.com'>foo@foo.com</a></p>},
        q{<p><b><a href='http://www.foo.com' target='_blank'>}
            . q{www.foo.com</a> (foo site).</b></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?Foo::Bar#sect'>Text</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?Foo::Bar'>Foo</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?Foo::Bar'>Foo::Bar</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?parselink'>parselink</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?Bar'>Foo</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?Foo#Bar'>"Bar" }
            . q{in Foo</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?foo#baz boo'>"baz boo" in foo}
            . q{</a></i></p>},
        q{<p><i><a href='#bar'>"bar"</a></i></p>},
        q{<p><i><a href='#bazboo'>"baz boo"</a></i></p>},
        q{<p><i><a href='#bazboo'>"baz boo"</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?foo bar#baz boo'>"baz boo" }
            . q{in foo bar</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?foobar'>foobar</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?foo bar baz#boo'>"boo" }
            . q{in foo bar baz</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?name#section'>anchor</a></i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?foo#bar'>Testing}
            . q{ <i>italics</i></a></i></p>},
        q{<p><i>some manual page in perl(1)</i></p>},
        q{<p><i><a href='http://search.cpan.org/perldoc?foo&sol;bar'>Nested }
            . q{<a href='http://www.perl.org/' target='_blank'>www.perl.org</a></a></i></p>},
        q{<p><i>ls(1)</i></p>},
        q{<p>news:yld72axzc8.<a href='mailto:fsf@windlord.stanford.edu'>}
            . q{fsf@windlord.stanford.edu</a></p>},
    ]
);

#--------------------------- test 13

run(q{various coded <>},
    [   q{B<BOLD>},
        q{I<ITALIC>},
        q{C<CODE>},
        q{E<escaped>},
        q{F<file_name>},
        q{S<Non-} . NL . q{breaking } . NL . q{space>},
        q{X<NULL CODE>},
        q{Z<NULL CODE>},
        q{& < > " E<Yacute> E<radic> E<uArr> E<uarr> E<lt> },
    ],
    [   q{<p><b>BOLD</b></p>},
        q{<p><i>ITALIC</i></p>},
        q{<p><font face='Courier New'>CODE</font></p>},
        q{<p>&escaped;</p>},
        q{<p><b><i>file_name</i></b></p>},
        q{<p>Non-breaking space</p>},
        q{<p></p>},
        q{<p></p>},
        q{<p>&amp; &lt; &gt; &quot; &Yacute; &radic; &uArr; &uarr; &lt;</p>},
    ],
);

#--------------------------- test 14

run(q{Special cases of =head},
    [   q{=head1 NAME},
        q{The Name of NAME},
        q{=head1 simple test},
        q{simple test text},
        q{=head2 sub title},
        q{sub title sub text},
        q{=over },
        q{=item foo},
        q{foo text},
        q{=item bar},
        q{bar text},
        q{=item *},
        q{star},
        q{=item end},
        q{end text},
        q{=back},
        q{=head2 sub title 2},
        q{sub title 2 text},
    ],
    [   q{<a name='NAME'></a><h1>NAME</h1>},
        q{<p>The Name of NAME</p>},
        q{<a name='simpletest'></a><h1>simple test</h1>},
        q{<p>simple test text</p>},
        q{<a name='subtitle'></a><h2>sub title</h2>},
        q{<p>sub title sub text</p>},
        q{<ul>},
        q{<li><a name='foo'></a>foo</li>},
        q{<p>foo text</p>},
        q{<li><a name='bar'></a>bar</li>},
        q{<p>bar text</p>},
        q{<li><a name='star'></a>star</li>},
        q{<li><a name='end'></a>end</li>},
        q{<p>end text</p>},
        q{</ul>},
        q{<a name='subtitle2'></a><h2>sub title 2</h2>},
        q{<p>sub title 2 text</p>},
    ],
    [   q{<li><a href='#NAME'>NAME</a></li>},
        q{<li><a href='#simpletest'>simple test</a></li>},
        q{<ul>},
        q{<li><a href='#subtitle'>sub title</a></li>},
        q{<li><a href='#subtitle2'>sub title 2</a></li>},
        q{</ul>},
    ],
    {   no_css       => 1,
        title        => q{Overrides the content of =head1 NAME},
        no_generator => 1,
    },
);

#--------------------------- test 15

run(q{Mixed non-regular =head},
    [   q{=head1 head1 #1},
        q{Testing head1 #1},
        q{=head2 head2 #1},
        q{Testing head2 #1},
        q{=head1 head1 #2},
        q{Testing head1 #2},
        q{=head2 head2 #2},
        q{Testing head2 #2},
        q{=head3 head3 #1},
        q{Testing head3 #1},
        q{=head4 head4 #1},
        q{Testing head4 #1},
        q{=head1 head1 #3},
        q{Testing head1 #3},
        q{=head3 head3 #2},
        q{Testing head3 #2},
        q{=head4 head4 #2},
        q{Testing head4 #2},
        q{=head2 head2 #3},
        q{Testing head2 #3},
        q{=head1 head1 #4},
        q{Testing head1 #4},
        q{=head2 head2 #4},
        q{Testing head2 #4},
        q{=head1 head1 #5},
        q{Testing head1 #5},
        q{=head2 head2 #5},
        q{Testing head2 #5},
    ],
    [   q{<a name='head1#1'></a><h1>head1 #1</h1>},
        q{<p>Testing head1 #1</p>},
        q{<a name='head2#1'></a><h2>head2 #1</h2>},
        q{<p>Testing head2 #1</p>},
        q{<a name='head1#2'></a><h1>head1 #2</h1>},
        q{<p>Testing head1 #2</p>},
        q{<a name='head2#2'></a><h2>head2 #2</h2>},
        q{<p>Testing head2 #2</p>},
        q{<a name='head3#1'></a><h3>head3 #1</h3>},
        q{<p>Testing head3 #1</p>},
        q{<a name='head4#1'></a><h4>head4 #1</h4>},
        q{<p>Testing head4 #1</p>},
        q{<a name='head1#3'></a><h1>head1 #3</h1>},
        q{<p>Testing head1 #3</p>},
        q{<a name='head3#2'></a><h3>head3 #2</h3>},
        q{<p>Testing head3 #2</p>},
        q{<a name='head4#2'></a><h4>head4 #2</h4>},
        q{<p>Testing head4 #2</p>},
        q{<a name='head2#3'></a><h2>head2 #3</h2>},
        q{<p>Testing head2 #3</p>},
        q{<a name='head1#4'></a><h1>head1 #4</h1>},
        q{<p>Testing head1 #4</p>},
        q{<a name='head2#4'></a><h2>head2 #4</h2>},
        q{<p>Testing head2 #4</p>},
        q{<a name='head1#5'></a><h1>head1 #5</h1>},
        q{<p>Testing head1 #5</p>},
        q{<a name='head2#5'></a><h2>head2 #5</h2>},
        q{<p>Testing head2 #5</p>},
    ],
    [   q{<li><a href='#head1#1'>head1 #1</a></li>},
        q{<ul>},
        q{<li><a href='#head2#1'>head2 #1</a></li>},
        q{</ul>},
        q{<li><a href='#head1#2'>head1 #2</a></li>},
        q{<ul>},
        q{<li><a href='#head2#2'>head2 #2</a></li>},
        q{<ul>},
        q{<li><a href='#head3#1'>head3 #1</a></li>},
        q{<ul>},
        q{<li><a href='#head4#1'>head4 #1</a></li>},
        q{</ul>},
        q{</ul>},
        q{</ul>},
        q{<li><a href='#head1#3'>head1 #3</a></li>},
        q{<ul>},
        q{<ul>},
        q{<li><a href='#head3#2'>head3 #2</a></li>},
        q{<ul>},
        q{<li><a href='#head4#2'>head4 #2</a></li>},
        q{</ul>},
        q{</ul>},
        q{<li><a href='#head2#3'>head2 #3</a></li>},
        q{</ul>},
        q{<li><a href='#head1#4'>head1 #4</a></li>},
        q{<ul>},
        q{<li><a href='#head2#4'>head2 #4</a></li>},
        q{</ul>},
        q{<li><a href='#head1#5'>head1 #5</a></li>},
        q{<ul>},
        q{<li><a href='#head2#5'>head2 #5</a></li>},
        q{</ul>},
    ],
);

#--------------------------- test 16

run(q{Mixed =head and =item},
    [   q{=head1 CONFIGURATION AND ENVIRONMENT},
        q{=over},
        q{=item @addpods},
        q{=item $CPAN},
        q{=back},
        q{=head1 DIAGNOSTICS},
        q{=over 4},
        q{=item C<-verbose> },
        q{=item Tag references more than one POD.},
        q{=back},
        q{=head1 SCRIPT CATEGORIES},
    ],
    [   q{<a name='CONFIGURATIONANDENVIRONMENT'></a>}
            . q{<h1>CONFIGURATION AND ENVIRONMENT</h1>},
        q{<ul>},
        q{<li><a name='@addpods'></a>@addpods</li>},
        q{<li><a name='$CPAN'></a>$CPAN</li>},
        q{</ul>},
        q{<a name='DIAGNOSTICS'></a><h1>DIAGNOSTICS</h1>},
        q{<ul>},
        q{<li><a name='-verbose'></a><font face='Courier New'>-verbose</font></li>},
        q{<li><a name='TagreferencesmorethanonePOD.'></a>}
            . q{Tag references more than one POD.</li>},
        q{</ul>},
        q{<a name='SCRIPTCATEGORIES'></a><h1>SCRIPT CATEGORIES</h1>},
    ],
    [   q{<li><a href='#CONFIGURATIONANDENVIRONMENT'>}
            . q{CONFIGURATION AND ENVIRONMENT</a></li>},
        q{<ul>},
        q{<li><a href='#@addpods'>@addpods</a></li>},
        q{<li><a href='#$CPAN'>$CPAN</a></li>},
        q{</ul>},
        q{<li><a href='#DIAGNOSTICS'>DIAGNOSTICS</a></li>},
        q{<ul>},
        q{<li><a href='#-verbose'><font face='Courier New'>-verbose</font></a></li>},
        q{<li><a href='#TagreferencesmorethanonePOD.'>}
            . q{Tag references more than one POD.</a></li>},
        q{</ul>},
        q{<li><a href='#SCRIPTCATEGORIES'>SCRIPT CATEGORIES</a></li>},
    ],
    {   no_css     => 1,
        index_item => 1,
    },
);

