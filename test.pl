#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 1 } ;

use Pod::HtmlEasy ;

use strict ;
use warnings qw'all' ;

###########
# CAT_DIR #
###########

sub cat_dir {
  my ( $DIR ) = @_ ;
  opendir (my $dh, $DIR);

  my @files ;

  while (my $filename = readdir $dh) {
    if ($filename =~ /^(.*?)\.pod$/i) {
      push(@files , "$DIR/$1") ;
    }
  }

  closedir ($dh);
  
  return @files ;
}

############
# CAT_FILE #
############

sub cat_file {
  my ( $file ) = @_ ;
  my $data = '' ;
  open (my $fh,$file) ;
  1 while( read($fh, $data , 1024*8 , length($data) ) ) ;
  close ($fh) ;
  $data =~ s/\r\n?/\n/gs ;
  return $data ;
}

#############
# SHOW_DIFF #
#############

sub show_diff {
  my ( $from , $to ) = @_ ;
  
  my @lines_from = split("\n" , $from) ;
  my @lines_to = split("\n" , $to) ;
  
  my ( $i , $j ) = (0,0) ;
  
  for (; $i <= $#lines_from ; ++$i , ++$j ) {
    my $ln_from = $lines_from[$i] ;
    my $ln_to = $lines_to[$j] ;
    
    if ( $ln_from ne $ln_to ) {
      print "line $i> $ln_from\n" ;
    }
  }
  
}

#########################
{

  my $podhtml = Pod::HtmlEasy->new(
  on_G => sub {
            my ( $this , $txt ) = @_ ;
            $txt .= ".gif" if $txt !~ /\.(?:jpg|gif|png)$/i ;
            return "<img src='$txt' border=0>" ;
          }
  ) ;
  
  my @files = cat_dir('./test') ;
  
  foreach my $files_i ( sort @files ) {
    print "testing: $files_i.pod ". ('.' x (18 - length($files_i)) ) ."... " ;

    my $pod_file = "$files_i.pod" ;
    my $html_file = "$files_i.html" ;

    my $html ;
    if ( !-s $html_file ) {
      $html = $podhtml->pod2html($pod_file , $html_file , index_item => 1 , no_generator => 1) ; ## To generate the HTMLs
    }
    else { $html = $podhtml->pod2html($pod_file , index_item => 1 , no_generator => 1) ;}

    my $chk_html = cat_file($html_file) ;
    
    $html =~ s/[\r\n]+/\n/gs ; $html =~ s/^\s+//s ; $html =~ s/\s+$//s ;
    $chk_html =~ s/[\r\n]+/\n/gs ; $chk_html =~ s/^\s+//s ; $chk_html =~ s/\s+$//s ;
    
    if ( $html eq $chk_html ) { ok(1) ;}
    else {
      ok(undef) ;
      print "*** ERRO with file: $pod_file\n" ;
      show_diff($html , $chk_html) ;
    }

  }

  
}
#########################

print "\nThe End! By!\n" ;

1 ;


