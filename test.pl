#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 1 } ;

use Pod::HtmlEasy ;

use strict ;
use warnings qw'all' ;

my $podhtml = Pod::HtmlEasy->new() ;

#########################
{

  my $html = $podhtml->pod2html(q`=head1 simple test

bla bla bla bla

=head2 sub title

wowowo

=over 10

=item foo

asdasd

=item bar

qweqwe

=back

=head2 sub title2

mohhhhh

=head1 LINKS

L<Text|Foo::Bar/"sect">

L<Foo|Foo::Bar>

L<"Section">

L<Foo::Bar>

B<L<http://www.foo.com> (foo site).>

http://www.foo.com

e-mail: <foo@foo.com>

=cut
`,
  css => undef ,
  only_content => 1 ,
  ) ;
  
  $html =~ s/\s+/ /gs ;
  $html =~ s/\s$//s ;
  
  ok($html , q`<div class="toc"> <ul> <li><a href='#simple-test'>simple test</a> <ul> <li><a href='#sub-title2'>sub title2</a> <li><a href='#sub-title'>sub title</a> </ul><li><a href='#LINKS'>LINKS</a> </ul> </div> <div class='pod'><div><a name='simple-test'><h1>simple test</h1> <p>bla bla bla bla</p> <a name='sub-title'><h2>sub title</h2> <p>wowowo</p> <ul> <li>foo</li> <p>asdasd</p> <li>bar</li> <p>qweqwe</p> </ul> <a name='sub-title2'><h2>sub title2</h2> <p>mohhhhh</p> <a name='LINKS'><h1>LINKS</h1> <p><i><a href='http://search.cpan.org/perldoc?Foo::Bar#sect'>Text</a></i></p> <p><i><a href='http://search.cpan.org/perldoc?Foo::Bar'>Foo</a></i></p> <p><i><a href='http://search.cpan.org/perldoc?#Section'>"Section"</a></i></p> <p><i><a href='http://search.cpan.org/perldoc?Foo::Bar'>Foo::Bar</a></i></p> <p><b><a href='http://www.foo.com' target='_blank'>http://www.foo.com</a> (foo site).</b></p> <p><a href='http://www.foo.com'>http://www.foo.com</a></p> <p>e-mail: &lt;<a href='foo@foo.com'>foo@foo.com</a>&gt;</p> <div></div>` ) ;

}
#########################

print "\nThe End! By!\n" ;

1 ;


