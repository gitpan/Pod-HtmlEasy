#############################################################################
## Name:        HtmlEasy.pm
## Purpose:     Pod::HtmlEasy
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-01-11
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Pod::HtmlEasy ;
use 5.006 ;

use Pod::HtmlEasy::Parser ;
use Pod::HtmlEasy::TiehHandler ;

use strict qw(vars) ;

use vars qw($VERSION @ISA) ;
$VERSION = '0.01' ;

########
# VARS #
########

  my %BODY_DEF = (
  bgcolor => "#FFFFFF" ,
  text    => "#000000" ,
  link    => "#000000" ,
  vlink   => "#000066" ,
  alink   => "#FF0000" ,
  ) ;
  
#######
# CSS #
#######
  
  my $CSS_DEF = q`
BODY {
  background: white;
  color: black;
  font-family: arial,sans-serif;
  margin: 0;
  padding: 1ex;
}
TABLE {
  border-collapse: collapse;
  border-spacing: 0;
  border-width: 0;
  color: inherit;
}
IMG { border: 0; }
FORM { margin: 0; }
input { margin: 2px; }
A.fred {
  text-decoration: none;
}
A:link, A:visited {
  background: transparent;
  color: #006699;
}
TD {
  margin: 0;
  padding: 0;
}
DIV {
  border-width: 0;
}
DT {
  margin-top: 1em;
}
TH {
  background: #bbbbbb;
  color: inherit;
  padding: 0.4ex 1ex;
  text-align: left;
}
TH A:link, TH A:visited {
  background: transparent;
  color: black;
}
A.m:link, A.m:visited {
  background: #006699;
  color: white;
  font: bold 10pt Arial,Helvetica,sans-serif;
  text-decoration: none;
}
A.o:link, A.o:visited {
  background: #006699;
  color: #ccffcc;
  font: bold 10pt Arial,Helvetica,sans-serif;
  text-decoration: none;
}
A.o:hover {
  background: transparent;
  color: #ff6600;
  text-decoration: underline;
}
A.m:hover {
  background: transparent;
  color: #ff6600;
  text-decoration: underline;
}
table.dlsip     {
  background: #dddddd;
  border: 0.4ex solid #dddddd;
}
.pod PRE     {
  background: #eeeeee;
  border: 1px solid #888888;
  color: black;
  padding-top: 1em;
  white-space: pre;
}
.pod H1      {
  background: transparent;
  color: #006699;
  font-size: large;
}
.pod H2      {
  background: transparent;
  color: #006699;
  font-size: medium;
}
.pod IMG     {
  vertical-align: top;
}
.pod .toc A  {
  text-decoration: none;
}
.pod .toc LI {
  line-height: 1.2em;
  list-style-type: none;
}
` ;

#######
# NEW #
#######

sub new {
  my $this = shift ;
  return( $this ) if ref($this) ;
  my $class = $this || __PACKAGE__ ;
  $this = bless({} , $class) ;
  
  my ( %args ) = @_ ;

  $this->{ON_B} = $args{on_B} || \&evt_on_B ;
  $this->{ON_C} = $args{on_C} || \&evt_on_C ;
  $this->{ON_I} = $args{on_I} || \&evt_on_I ;
  $this->{ON_L} = $args{on_L} || \&evt_on_L ;
  
  $this->{ON_HEAD1} = $args{on_head1} || \&evt_on_head1 ;
  $this->{ON_HEAD2} = $args{on_head2} || \&evt_on_head2 ;
  $this->{ON_HEAD3} = $args{on_head3} || \&evt_on_head3 ;
  
  $this->{ON_VERBATIN} = $args{on_verbatin} || \&evt_on_verbatin ;
  $this->{ON_TEXTBLOCK} = $args{on_textblock} || \&evt_on_textblock ;
  
  $this->{ON_OVER} = $args{on_over} || \&evt_on_over ;
  $this->{ON_ITEM} = $args{_on_item} || \&evt_on_item ;
  $this->{ON_BACK} = $args{on_back} || \&evt_on_back ;
  
  $this->{ON_INDEX_NODE_START} = $args{on_index_node_start} || \&evt_on_index_node_start ;
  $this->{ON_INDEX_NODE_END} = $args{on_index_node_end} || \&evt_on_index_node_end ;

  $this->{ON_INCLUDE} = $args{on_include} || \&evt_on_include ;

  $this->{ON_ERROR} = $args{on_error} || \&evt_on_error ;
  
  return $this ;
}

############
# POD2HTML #
############

sub pod2html {
  my $this = shift ;
  
  my $file = shift ;
  my $save = shift if $_[0] !~ /^(?:file|title|body|css|index|only_content|no_index|no_css)$/i ;
  my ( %args ) = @_ ;

  my $parser = Pod::HtmlEasy::Parser->new() ;
  $parser->errorsub( sub { &Pod::HtmlEasy::Parser::_errors($parser , @_) ;} ) ;
  $parser->{POD_HTMLEASY} = $this ;
  
  local(*PODIN , *PODOUT) ;
  
  my $output ;
  tie(*PODOUT => 'Pod::HtmlEasy::TiehHandler' , \$output) ;
  
  $this->{OUTPUT} = \$output ;
  $this->{TIEDOUTPUT} = \*PODOUT ;
  
  my $io ;
  if ( ref($file) eq 'GLOB' ) { $io = $file ;}
  elsif ( $file =~ /[\r\n]/s && !-e $file ) {
    tie(*PODIN => 'Pod::HtmlEasy::TiehHandler' , \$file) ;
    $io = \*PODIN ;
  }
  
  delete $this->{INDEX} ;
  
  if ( $io ) { $parser->parse_from_filehandle(\*PODIN , \*PODOUT) ; $file = '<DATA>' ;}
  else { $parser->parse_from_file($file , \*PODOUT) ;}
  
  delete $this->{TIEDOUTPUT} ;
  delete $this->{OUTPUT} ;
  
  close(PODOUT) ;
  untie (*PODOUT) ;
  close(PODIN) ;
  untie (*PODIN) ;
  
  $args{file} = $file if $file ;
  
  $args{index} = $this->build_index if !$args{index} && !$args{no_index} ;
    
  my $html ;
  
  if ( $args{only_content} ) {
    $html = "$args{index}<div class='pod'><div>$output<div></div>\n"
  }
  else {
    $html = $this->build_html("$output\n" , %args) ;
  }
  
  if ( $save && $save !~ /\s/s ) {
    open (my $out,">$save") ;
    print $out $html ;
    close($out) ;
  }
  
  return $html ;
}

#################
# PARSE_INCLUDE #
#################

sub parse_include {
  my $this = shift ;
  my $file = shift ;

  my $parser = Pod::HtmlEasy::Parser->new() ;
  $parser->errorsub( sub { &Pod::HtmlEasy::Parser::_errors($parser , @_) ;} ) ;
  $parser->{POD_HTMLEASY} = $this ;
  $parser->{POD_HTMLEASY_INCLUDE} = 1 ;
  
  $parser->parse_from_file($file , $this->{TIEDOUTPUT} ) ;
  
  return 1 ;
}

#############
# WALK_TREE #
#############

sub walk_tree {
  my ( $this , $tree , $on_open , $on_close , $on_value , $output ) = @_ ;
  
  foreach my $Key ( keys %$tree ) {
    my $nk = keys %{ $$tree{$Key} } if ref($$tree{$Key}) eq 'HASH' ;
    $nk = $nk >= 1 ? 1 : undef ;
    
    my $a_name = $Key ;
    $a_name =~ s/\W/-/gs ;

    if ( $on_open ) {
      my $ret = &$on_open($this , $Key , $a_name , $nk) ;
      $$output .= $ret if $output ;
    }
    
    if ( ref($$tree{$Key}) eq 'HASH' ) { walk_tree( $this , $$tree{$Key} , $on_open , $on_close , $on_value , $output ) ;}
    elsif ($on_value) {
      my $ret = &$on_value($this , $Key , $a_name , $$tree{$Key}) ;
      $$output .= $ret if $output ;
    }

    if ( $on_close ) {
      my $ret = &$on_close($this , $Key , $a_name , $nk) ;
      $$output .= $ret if $output ;
    }
  }
}

###############
# BUILD_INDEX #
###############

sub build_index {
  my $this = shift ;
  
  my $index ;
  $this->walk_tree( $this->{INDEX} , $this->{ON_INDEX_NODE_START} , $this->{ON_INDEX_NODE_END} , undef , \$index ) ;
  
  $index = qq`<div class="toc">
<ul>
$index
</ul>
</div>
` ;

  return $index ;
  
}

##############
# BUILD_HTML #
##############

sub build_html {
  my $this = shift ;
  my ( $content , %args ) = @_ ;
  
  my $title = $args{title} || $args{file} ;
  
  my ($body , %body) ;
  if ( ref($args{body}) eq 'HASH' ) {
    %body = %BODY_DEF ;
    my %body_attr = %{$args{body}} ;
    foreach my $Key (keys %body_attr) { $body{$Key} = $body_attr{$Key} ;}
  }
  elsif ( !exists $args{body} ) { %body = %BODY_DEF ;}
  
  if ( %body ) {
    foreach my $Key (sort keys %body ) {
      $body{$Key} = "#$body{$Key}" if $body{$Key} !~ /#/s && defined $BODY_DEF{$Key} ;
      my $Value = $body{$Key} !~ /"/ ? qq`"$body{$Key}"` : qq`'$body{$Key}'` ;
      $body .= " $Key=$Value" ;
    }
  }
  else { $body = $args{body} ;}
  
  if ( $body =~ /\S/ ) { $body =~ s/[\r\n]/ /gs ; $body =~ s/^\s+/ /s ;}
  else { $body = '' ;}
  
  my $css = exists $args{css} ? $args{css} : $CSS_DEF ;
  
  $css = '' if $args{no_css} ;
  
  if ( ref($css) eq 'GLOB' ) {
    my $buffer ;
    1 while( read($css, $buffer , 1024*8 , length($buffer) ) ) ;
    $css = $buffer ;
  }
  
  if ( $css !~ /[\r\n]/s && -e $css ) {
    $css = qq`<link rel="stylesheet" href="$css" type="text/css">` ;
  }
  elsif ( $css =~ /\S/s ) { $css = qq`<style type="text/css">
<!--
$css
--></style>` ;
  }
  else { $css = '' ;}
  
  my $gen = "Pod::HtmlEasy/$VERSION Perl/$] [$^O]" ;

my $html = qq`<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html><head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<meta name="GENERATOR" content="$gen">
<title>$title</title>
$css
</head>
<body$body><a name="_top"></a>
$args{index}
<div class='pod'><div>
$content
<div></div></body></html>
` ;
}

##################
# DEFAULT EVENTS #
##################

sub evt_on_head1 {
  my $this = shift ;
  my ( $txt , $a_name ) = @_ ;
  return "<a name='$a_name'><h1>$txt</h1>\n\n" ;
}

sub evt_on_head2 {
  my $this = shift ;
  my ( $txt , $a_name ) = @_ ;
  return "<a name='$a_name'><h2>$txt</h2>\n\n" ;
}

sub evt_on_head3 {
  my $this = shift ;
  my ( $txt , $a_name ) = @_ ;
  return "<a name='$a_name'><h3>$txt</h3>\n\n" ;
}

sub evt_on_L {
  my $this = shift ;
  my ( $L , $text, $page , $section, $type ) = @_ ;
  
  if   ( $type eq 'pod' ) {
    $section = "#$section" if $section ne '' ;
    return "<i><a href='http://search.cpan.org/perldoc?$page$section'>$text</a></i>" ;
  }
  elsif( $type eq 'man' ) { return "<i>$text</i>" ;}
  elsif( $type eq 'url' ) { return "<a href='$page' target='_blank'>$text</a>" ;}
}

sub evt_on_B {
  my $this = shift ;
  my ( $txt ) = @_ ;
  return "<b>$txt</b>" ;
}

sub evt_on_I {
  my $this = shift ;
  my ( $txt ) = @_ ;
  return "<i>$txt</i>" ;
}

sub evt_on_C {
  my $this = shift ;
  my ( $txt ) = @_ ;
  return "<pre>$txt</pre>" ;
}

sub evt_on_verbatin {
  my $this = shift ;
  my ( $txt ) = @_ ;
  return "<pre>$txt</pre>\n" ;
}

sub evt_on_textblock {
  my $this = shift ;
  my ( $txt ) = @_ ;
  return "<p>$txt</p>\n" ;
}

sub evt_on_over {
  my $this = shift ;
  my ( $level ) = @_ ;
  return "<ul>\n" ;
}

sub evt_on_item {
  my $this = shift ;
  my ( $txt ) = @_ ;
  return "<li>$txt</li>\n" ;
}

sub evt_on_back {
  my $this = shift ;
  return "</ul>\n" ;
}

sub evt_on_error {
  my $this = shift ;
  my ( $txt ) = @_ ;
  return "<!-- POD_ERROR: $txt -->" ;
}

sub evt_on_include {
  my $this = shift ;
  my ( $file ) = @_ ;
  return $file ;
}

sub evt_on_index_node_start {
  my $this = shift ;
  my ( $txt , $a_name , $has_childs ) = @_ ;
  
  my $ret = "<li><a href='#$a_name'>$txt</a>\n" ;
  $ret .= "\n<ul>\n" if $has_childs ;
  
  return $ret ;
}

sub evt_on_index_node_end {
  my $this = shift ;
  my ( $txt , $a_name , $has_childs ) = @_ ;
  
  my $ret = "</ul>" if $has_childs ;
  
  return $ret ;
}

#########
# UTILS #
#########

sub pm_version {
  my ( $file ) = @_ ;
  my ($ver,$buffer) ;

  open (my $fh,$file) ;
  while( read($fh, $buffer , 1024 , length($buffer) ) ) {
    my ($v) = ( $buffer =~ /\$VERSION\s*=\s*[^\s\d\.]*([\d\.]+)./s ) ;
    if ($v ne '') { $ver = $v ; last ;}
  }
  close ($fh) ;
  
  return( $ver ) ;
}

##############
# PM_PACKAGE #
##############

sub pm_package {
  my ( $file ) = @_ ;
  my ($pack,$buffer) ;

  open (my $fh,$file) ;
  while( read($fh, $buffer , 1024 , length($buffer) ) ) {
    my ($p) = ( $buffer =~ /\Wpackage\s+\w+(?:::\w+)*\W/s ) ;
    if ($p ne '') { $pack = $p ; last ;}
  }
  close ($fh) ;
  
  return( $pack ) ;
}

#######
# END #
#######

1;


__END__

=head1 NAME

Pod::HtmlEasy - Generate HTML from POD easy, without extra modules and on the flight.

=head1 DESCRIPTION

The purpose of this module is to generate HTML data from POD in a easy and personalizable mode.

By default the HTML generated is simillar to CPAN style for modules documentations.

=head1 USAGE

Simple usage:

  my $podhtml = Pod::HtmlEasy->new() ;

  my $html = $podhtml->pod2html( 'test.pod' ) ;
  
  print "$html\n" ;

Complete usage:

  use Pod::HtmlEasy ;

  ## Create the object and set my own events subs:
  ## ** Note that here are all the events, and examples of how to implement **
  ## ** them, and actually this are the default events, soo you don't need  **
  ## ** to set everything.                                                  **

  my $podhtml = Pod::HtmlEasy->new(
  on_head1     => sub {
                    my ( $this , $txt , $a_name ) = @_ ;
                    return "<a name='$a_name'><h1>$txt</h1>\n\n" ;
                  } ,

  on_head2     => sub {
                    my ( $this , $txt , $a_name ) = @_ ;
                    return "<a name='$a_name'><h2>$txt</h2>\n\n" ;
                  } ,

  on_head3     => sub {
                    my ( $this , $txt , $a_name ) = @_ ;
                    return "<a name='$a_name'><h3>$txt</h3>\n\n" ;
                  } ,

  on_L         => sub {
                    my ( $this , $L , $text, $page , $section, $type ) = @_ ;
                    if   ( $type eq 'pod' ) {
                      $section = "#$section" if $section ne '' ;
                      return "<i><a href='http://search.cpan.org/perldoc?$page$section'>$text</a></i>" ;
                    }
                    elsif( $type eq 'man' ) { return "<i>$text</i>" ;}
                    elsif( $type eq 'url' ) { return "<a href='$page' target='_blank'>$text</a>" ;}
                  } ,

  on_B         => sub {
                    my ( $this , $txt ) = @_ ;
                    return "<b>$txt</b>" ;
                  } ,

  on_I         => sub {
                    my ( $this , $txt ) = @_ ;
                    return "<i>$txt</i>" ;
                  } ,

  on_C         => sub {
                    my ( $this , $txt ) = @_ ;
                    return "<pre>$txt</pre>" ;
                  } ,

  on_verbatin  => sub {
                    my ( $this , $txt ) = @_ ;
                    return "<pre>$txt</pre>\n" ;
                  } ,

  on_textblock => sub {
                    my ( $this , $txt ) = @_ ;
                    return "<p>$txt</p>\n" ;
                  } ,

  on_over      => sub {
                    my ( $this , $level ) = @_ ;
                    return "<ul>\n" ;
                  } ,

  on_item      => sub {
                    my ( $this , $txt ) = @_ ;
                    return "<li>$txt</li>\n" ;
                  } ,

  on_back      => sub {
                    my $this = shift ;
                    return "</ul>\n" ;
                  } ,
                  
  on_include   => sub {
                    my ( $this , $file ) = @_ ;
                    return "./$file" ;
                  }
  
  on_error     => sub {
                    my ( $this , $txt ) = @_ ;
                    return "<!-- POD_ERROR: $txt -->" ;
                  } ,

  on_index_node_start => sub {
                           my ( $this , $txt , $a_name , $has_childs ) = @_ ;
                           my $ret = "<li><a href='#$a_name'>$txt</a>\n" ;
                           $ret .= "\n<ul>\n" if $has_childs ;
                           return $ret ;
                         } ,

  on_index_node_end => sub {
                         my $this = shift ;
                         my ( $txt , $a_name , $has_childs ) = @_ ;
                         my $ret = "</ul>" if $has_childs ;
                         return $ret ;
                       } ,

  ) ;
  
  ## Convert to HTML:

  my $html = $podhtml->pod2html('test.pod' , 'test.html' ,
  title => 'POD::Test' ,
  body => { bgcolor => '#CCCCCC' } ,
  css => 'test.css' ,
  ) ;

=head1 METHODS

=head2 new ( %EVENTS_SUBS )

By default the object has it own subs to handler the events.

But if you want to personalize/overwrite them you can set this keys in the initialization:

I<(For examples of how to implement the event subs see L<"USAGE"> above).>

=over 10

=item on_head1 ( $txt , $a_name )

When I<=head1> is found.

=over 10

=item $txt

The text of the command.

=item $a_name

The text of the command filtered to be used as I<<a name="$a_name">>.

=back

=item on_head2 ( $txt , $a_name )

When I<=head2> is found. See I<on_head1>.

=item on_head3 ( $txt , $a_name )

When I<=head2> is found. See I<on_head1>.

=item on_L ( $L , $text, $page , $section, $type )

When I<L>I<<>I<...>I<>> is found.

=over 10

=item $L

The link content. This is what is parsed to generate the other variables.

=item $text

The link text.

=item $page

The page of the link. Can be an URI, pack::age, or some other reference.

=item $section

The section of the $page.

=item $type

The type of the link: pod, man, url.

=back


=item on_B ( $txt )

When I<B>I<<>I<...>I<>> is found.

=item on_I ( $txt )

When I<I>I<<>I<...>I<>> is found.

=item on_C ( $txt )

When I<C>I<<>I<...>I<>> is found.

=item on_verbatin ( $txt )

When VERBATIN data is found.

=item on_textblock ( $txt )

When normal text blocks are found.

=item on_over ( $level )

When I<=over X> is found.

=item on_item ( $txt )

When I<=item foo> is found.

=item on_back 

When I<=back> is found.

=item on_include ( $file )

Should be used only to handle the localtion of the $file.

=item on_error ( $txt )

Called on POD syntax error occurrence.

=item on_index_node_start ( $txt , $a_name , $has_childs )

Called to build the INDEX. This is called when a node is start.

I<$has_childs> can be used to know if the node has childs (sub-nodes).

=item on_index_node_end ( $txt , $a_name , $has_childs )

Called to build the INDEX. This is called when a node ends.

I<$has_childs> can be used to know if the node has childs (sub-nodes).

=back

=head2 pod2html ( POD_FILE|POD_DATA|FILEHANDLER , HTML_FILE , %OPTIONS )

Convert a POD to HTML. Also returns the HTML data generated.

=over 10

=item POD_FILE|POD_DATA|GLOB

The POD file (file path) , data (SCALAR) or FILEHANDLER (GLOB opened).

=item HTML_FILE I<(optional)>

The output HTML file path.

I<** Note that the method also returns the HTML data generated, soo you also can use it wihtout generate files.>

=item %OPTIONS I<(optional)>

=over 10

=item title

The title of the HTML.

** I<Default: file path>

=item body

The body values.

Examples:

  body => q`alink="#FF0000" bgcolor="#FFFFFF" link="#000000" text="#000000" vlink="#000066"` ,
  
  ## Or:
  
  body => { bgcolor => "#CCCCCC" , link => "#0000FF" } , ## This will overwrite only this 2 values,
                                                         ## the other default values are kept.

** I<Default: alink="#FF0000" bgcolor="#FFFFFF" link="#000000" text="#000000" vlink="#000066">

=item css

Can be a css file path (HREF) or the css data.

Examples:

  css => 'test.css' ,
  
  ## Or:
  
  css => q`
    BODY {
      background: white;
      color: black;
      font-family: arial,sans-serif;
      margin: 0;
      padding: 1ex;
    }
    TABLE {
      border-collapse: collapse;
      border-spacing: 0;
      border-width: 0;
      color: inherit;
    }
  ` ,

=item index

Set the index data. If not set will generate automatically, calling the events subs I<on_index_node_start> and I<on_index_node_end>

=item no_index

If I<TRUE> tell to not build and insert the index.

=item no_css

If I<TRUE> tell to not use css.

=item only_content

If I<TRUE> tell to only generate the HTML content (between <body>...</body>).

=back

=back

=head2 pm_version ( FILE )

Return the version of a Perl Module file.

=head2 pm_package ( FILE )

Return the package name of a Perl Module file.

=head1 DEFAULT CSS

  BODY {
    background: white;
    color: black;
    font-family: arial,sans-serif;
    margin: 0;
    padding: 1ex;
  }
  TABLE {
    border-collapse: collapse;
    border-spacing: 0;
    border-width: 0;
    color: inherit;
  }
  IMG { border: 0; }
  FORM { margin: 0; }
  input { margin: 2px; }
  A.fred {
    text-decoration: none;
  }
  A:link, A:visited {
    background: transparent;
    color: #006699;
  }
  TD {
    margin: 0;
    padding: 0;
  }
  DIV {
    border-width: 0;
  }
  DT {
    margin-top: 1em;
  }
  TH {
    background: #bbbbbb;
    color: inherit;
    padding: 0.4ex 1ex;
    text-align: left;
  }
  TH A:link, TH A:visited {
    background: transparent;
    color: black;
  }
  A.m:link, A.m:visited {
    background: #006699;
    color: white;
    font: bold 10pt Arial,Helvetica,sans-serif;
    text-decoration: none;
  }
  A.o:link, A.o:visited {
    background: #006699;
    color: #ccffcc;
    font: bold 10pt Arial,Helvetica,sans-serif;
    text-decoration: none;
  }
  A.o:hover {
    background: transparent;
    color: #ff6600;
    text-decoration: underline;
  }
  A.m:hover {
    background: transparent;
    color: #ff6600;
    text-decoration: underline;
  }
  table.dlsip     {
    background: #dddddd;
    border: 0.4ex solid #dddddd;
  }
  .pod PRE     {
    background: #eeeeee;
    border: 1px solid #888888;
    color: black;
    padding-top: 1em;
    white-space: pre;
  }
  .pod H1      {
    background: transparent;
    color: #006699;
    font-size: large;
  }
  .pod H2      {
    background: transparent;
    color: #006699;
    font-size: medium;
  }
  .pod IMG     {
    vertical-align: top;
  }
  .pod .toc A  {
    text-decoration: none;
  }
  .pod .toc LI {
    line-height: 1.2em;
    list-style-type: none;
  }

=head1 SEE ALSO

L<Pod::Parser>, L<Pod::Master>, L<Pod::Master::Html>.

L<perlpod>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

