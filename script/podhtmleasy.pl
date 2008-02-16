#! /usr/bin/perl
eval 'exec /usr/bin/perl -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

# This script shows how POD => HTML works

use Pod::HtmlEasy ;

use strict ;
use warnings ;
  
if ( !@ARGV || $ARGV[0] =~ /^-+h/i ) {

  my ($script) = ( $0 =~ /([^\\\/]+)$/s );

print qq`____________________________________________________________________

Pod::HtmlEasy - $Pod::HtmlEasy::VERSION
____________________________________________________________________

USAGE:

  $script file.pod [file.html]


(C) Copyright 2000-2004, Graciliano M. P. <gm\@virtuasites.com.br>
____________________________________________________________________
`;

exit;
}

  my $podhtml = Pod::HtmlEasy->new() ;
  
  my $pod_file = shift ;
  my $html_file = defined $ARGV[0] ? shift : "${pod_file}.html" ;

  $podhtml->pod2html( $pod_file , $html_file , @ARGV ) ;

  print "File $pod_file converted to $html_file.\n" ;


