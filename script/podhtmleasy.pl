
use Pod::HtmlEasy ;

  use strict ;
  
if ( $ARGV[0] =~ /^-+h/i || !@ARGV ) {

  my ($script) = ( $0 =~ /([^\\\/]+)$/s );

print qq`____________________________________________________________________

Pod::HtmlEasy - $Pod::HtmlEasy::VERSION
____________________________________________________________________

USAGE:

  $script file.pod file.html


(C) Copyright 2000-2004, Graciliano M. P. <gm\@virtuasites.com.br>
____________________________________________________________________
`;

exit;
}

  my $podhtml = Pod::HtmlEasy->new() ;
  
  my $pod_file = shift ;
  my $html_file = @ARGV[0] =~ /htm/i ? shift : "$pod_file.html" ;

  $podhtml->pod2html( $pod_file , $html_file , @ARGV ) ;

  print "File $pod_file converted to $html_file.\n" ;


