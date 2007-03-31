#############################################################################
## Name:        HtmlEasy.pm
## Purpose:     Pod::HtmlEasy
## Author:      Graciliano M. P.
## Modified by: Geoffrey Leach
## Created:     2004-01-11
## Updated:	    2007-02-28
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Pod::HtmlEasy;
use 5.008;

use Pod::HtmlEasy::Parser;
use Pod::HtmlEasy::TieHandler;
use File::Slurp;
use Carp;
use English qw{ -no_match_vars };
use Readonly;
use Regexp::Common qw{ whitespace };

use strict;
use warnings;

our $VERSION = 0.09;    # Also appears in "=head1 VERSION" in the POD below

Readonly my $EMPTY => q{};
Readonly my $NL    => qq{\n};
Readonly my $NUL   => qq{\0};
Readonly my $SPACE => q{ };

########
# VARS #
########

my %BODY_DEF = (
    bgcolor => '#FFFFFF',
    text    => '#000000',
    link    => '#000000',
    vlink   => '#000066',
    alink   => '#FF0000',
);

# This keeps track of valid options
my %OPTS = (
    basic_entities  => 1,
    body            => 1,
    common_entities => 1,
    css             => 1,
    index           => 1,
    index_item      => 1,
    no_css          => 1,
    no_generator    => 1,
    no_index        => 1,
    only_content    => 1,
    parserwarn      => 1,
    title           => 1,
    top             => 1,
);

my $output_file;

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
`;

###############
# DEFAULT_CSS #
###############

sub default_css {
    return $CSS_DEF;
}

#######################
# _ORGANIZE_CALLBACKS #
#######################

sub _organize_callbacks {
    my $this = shift;

    $this->{ON_B} = \&evt_on_B;
    $this->{ON_C} = \&evt_on_C;
    $this->{ON_E} = \&evt_on_E;
    $this->{ON_F} = \&evt_on_F;
    $this->{ON_I} = \&evt_on_I;
    $this->{ON_L} = \&evt_on_L;
    $this->{ON_S} = \&evt_on_S;
    $this->{ON_X} = \&evt_on_X;    # [20078]
    $this->{ON_Z} = \&evt_on_Z;

    $this->{ON_HEAD1} = \&evt_on_head1;
    $this->{ON_HEAD2} = \&evt_on_head2;
    $this->{ON_HEAD3} = \&evt_on_head3;
    $this->{ON_HEAD4} = \&evt_on_head4;

    $this->{ON_VERBATIM}  = \&evt_on_verbatim;
    $this->{ON_TEXTBLOCK} = \&evt_on_textblock;

    $this->{ON_OVER} = \&evt_on_over;
    $this->{ON_ITEM} = \&evt_on_item;
    $this->{ON_BACK} = \&evt_on_back;

    $this->{ON_FOR}   = \&evt_on_for;
    $this->{ON_BEGIN} = \&evt_on_begin;
    $this->{ON_END}   = \&evt_on_end;

    $this->{ON_INDEX_NODE_START} = \&evt_on_index_node_start;
    $this->{ON_INDEX_NODE_END}   = \&evt_on_index_node_end;

    $this->{ON_INCLUDE} = \&evt_on_include;
    $this->{ON_URI}     = \&evt_on_uri;

    $this->{ON_ERROR} = \&evt_on_error;

    return;
}

#######
# NEW #
#######

sub new {
    my $this = shift;
    return $this if ref $this;
    my $class = $this || __PACKAGE__;
    $this = bless {}, $class;

    my (%args) = @_;
    _organize_callbacks($this);

    # Backwards compatibility
    if ( exists $args{on_verbatin} ) {
        $this->{ON_VERBATIM} = $args{on_verbatin};
    }

    foreach my $key ( keys %args ) {

        # Add in any ON_ callbacks
        if ( $key =~ m{^on_(\w+)$}ismx ) {
            my $cmd = uc $1;
            $this->{qq{ON_$cmd}} = $args{$key};
        }
        elsif ( $key =~ m{^(?:=(\w+)|(\w)<>)$}smx ) {
            my $cmd = uc $1 || $2;
            $this->{$cmd} = $args{$key};
        }
    }

    return $this;
}

############
# POD2HTML #
############

sub pod2html {
    my $this = shift;
    my $file = shift;

    # Assume a non-option second arg is a file name
    my $save = exists $OPTS{ $_[0] } ? undef: shift;
    my %args = @_;

    # Check options for validity
    foreach my $key ( keys %args ) {
        if ( not exists $OPTS{$key} ) {
            carp qq{option $key is not supported};
        }
    }

    # No /x please
    if ( defined $save && $save =~ m{$NL}sm ) {

        # Is this a M$ way of saying "nothing there"?
        $save = undef;
    }

    # This will fall through to Pod::Parser::new
    # which is the base for Pod::HtmlEasy::Parser
    # and Pod::HtmlEasy::Parser does not implement new()
    my $parser = Pod::HtmlEasy::Parser->new();

    $parser->errorsub( sub { Pod::HtmlEasy::Parser::errors( $parser, @_ ); }
    );

    # Pod::Parser wiii complain about multiple blank lines in the input
    # which is moderately annoying
    if ( exists $args{parserwarn} ) { $parser->parseopts( -warnings => 1 ); }

    # This allows us to search for non-POD stuff is preprocess_paragraph
    $parser->parseopts( -want_nonPODs => 1 );

    # This puts a subsection in the $parser hash that will record data
    # that is "local" to this code.  Throughout, $parser will refer to
    # Pod::Parser and $this to Pod::HtmlEasy
    $parser->{POD_HTMLEASY} = $this;

    if ( exists $args{index_item} ) { $parser->{INDEX_ITEM} = 1; }
    if ( exists $args{basic_entities} ) {
        carp q{"basic_entities" is deprecated.};
    }
    if ( exists $args{common_entities} ) {
        carp q{"common_entities" is deprecated.};
    }

    # *HTML supplies a PRINT method that's used by the parser to do output
    # It gets accumulated into HTML, which is tied to $output.
    # You'll also see calls to  print {$parser->output_handle()} ...
    # which accomplishes the same thing. When all is said and done, the output
    # of the parse winds up in $output declared below, and used in the construction
    # of @html.

    my $output = [];
    local *HTML;
    tie *HTML => 'Pod::HtmlEasy::TieHandler', $output;
    my $html = \*HTML;
    $this->{TIEDOUTPUT} = $html;

    my $title = $args{title};
    if ( ref $file eq q{GLOB} ) {    # $file is an open filehandle
        if ( not defined $title ) { $title = q{<DATA>}; }
    }
    else {
        if ( !-e $file ) {
            carp qq{No file $file};
            return;
        }
        if ( not defined $title ) { $title = $file; }
    }

    # Build the header to the HTML file
    my @html;
    push @html,
        qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">$NL};
    push @html, qq{<html><head>$NL};
    push @html,
        qq{<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">$NL};

    if ( not exists $args{no_generator} ) {
        push @html,
            qq{<meta name="GENERATOR" content="Pod::HtmlEasy/$VERSION Pod::Parser/$Pod::Parser::VERSION Perl/$] [$^O]">$NL};
    }
    push @html, qq{<title>$title</title>$NL};
    my $title_line_ref = \$html[-1];
    push @html, _organize_css( \%args );
    push @html, qq{</head>$NL};
    if ( not exists $args{only_content} ) {
        push @html, _organize_body( \%args );
    }

    delete $this->{UPARROW};
    delete $this->{UPARROW_FILE};
    if ( exists $args{top} ) {
        push @html, qq{$NL<a name='_top'></a>$NL};
        if ( -e $args{top} ) {
            $this->{UPARROW_FILE} = $args{top};
        }
        else {
            $this->{UPARROW} = $args{top};
        }
    }

    # Avoid carry-over on multiple files
    delete $this->{IN_BEGIN};
    delete $this->{PACKAGE};
    delete $this->{TITLE};
    delete $this->{VERSION};
    $this->{INFO_COUNT} = 0;

    # A filehandle as both args is not documented, but is supported
    # Everything that Pod::Parser prints winds up in $output
    $parser->parse_from_file( $file, $html );

    # If there's a head1 NAME, we've picked this up during processing
    if ( defined $this->{TITLE} && length $this->{TITLE} > 0 ) {
        ${$title_line_ref} = qq{<title>$this->{TITLE}</title>$NL};
    }

  # Note conflict here: user can specify an index, and no_index; no_index wins
    if ( not exists $args{index} ) { $args{index} = $this->build_index(); }
    if ( exists $args{no_index} )  { $args{index} = $EMPTY; }

    push @html, qq{$args{index}$NL};
    push @html, qq{<div class='pod'><div>$NL};
    push @html, @{$output};                      # The pod converted to HTML
    push @html, qq{</div></body></html>$NL};

    delete $this->{TIEDOUTPUT};
    close $html or carp q{Could not close html};
    untie $html or carp q{Could not untie html};

    if ( defined $save ) {
        open my $out, q{>}, $save or croak qq{Unable to open $save - $!};
        print {$out} @html;
        close $out;
    }

    return wantarray ? @html : join $EMPTY, @html;
}

#################
# PARSE_INCLUDE #
#################

sub parse_include {
    my $this = shift;
    my $file = shift;

    my $parser = Pod::HtmlEasy::Parser->new();
    $parser->errorsub( sub { Pod::HtmlEasy::Parser::errors( $parser, @_ ); }
    );
    $parser->{POD_HTMLEASY}         = $this;
    $parser->{POD_HTMLEASY_INCLUDE} = 1;

    $parser->parse_from_file( $file, $this->{TIEDOUTPUT} );

    return 1;
}

##############
# WALK_INDEX #
##############

sub walk_index {
    my ( $this, $tree, $on_open, $on_close, $output ) = @_;

    my $i = 0;
    while ( $i < @{$tree} ) {
        my $nk =
            ref( ${$tree}[ $i + 1 ] ) eq q{ARRAY}
            ? @{ ${$tree}[ $i + 1 ] }
            : undef;
        $nk = $nk >= 1 ? 1 : undef;

        my $a_name = ${$tree}[$i];
        $a_name =~ s{<.*?>}{}gsmx;

        #$a_name =~ s{&\w+;}{}gsmx;
        #$a_name =~ s{\W+}{-}gsmx;

        if ($on_open) {
            my $ret = $on_open->( $this, ${$tree}[$i], $a_name, $nk );
            if ( $output and defined $ret ) {
                ${$output} .= $ret;
            }    # [6062]
        }

        if ($nk) {
            walk_index( $this, ${$tree}[ $i + 1 ],
                $on_open, $on_close, $output );
        }

        if ($on_close) {
            my $ret = $on_close->( $this, ${$tree}[$i], $a_name, $nk );
            if ( $output and defined $ret ) {
                ${$output} .= $ret;
            }    # [6062]
        }
        $i += 2;
    }
    return;
}

###############
# BUILD_INDEX #
###############

sub build_index {
    my $this = shift;

    my $index = $EMPTY;    # [6062]
    $this->walk_index(
        $this->{INDEX},
        $this->{ON_INDEX_NODE_START},
        $this->{ON_INDEX_NODE_END}, \$index
    );

    return qq{<div class="toc">$NL<ul>$NL$index</ul>$NL</div>$NL};
}

#################
# _ORGANIZE_BODY #
#################

sub _organize_body {
    my $args_ref = shift;

    my ( $body, %body );

    $body = $EMPTY;
    if ( ref $args_ref->{body} eq q{HASH} ) {
        %body = %BODY_DEF;
        my %body_attr = %{ $args_ref->{body} };
        foreach my $key ( keys %body_attr ) {
            $body{$key} = $body_attr{$key};
        }
    }
    elsif ( !exists $args_ref->{body} ) { %body = %BODY_DEF; }

    if (%body) {
        foreach my $key ( sort keys %body ) {
            if ( $body{$key} !~ m{\#}smx && defined $BODY_DEF{$key} ) {
                $body{$key} = qq{#$body{$key}};
            }
            my $value =
                $body{$key} !~ m{"}smx
                ? qq{"$body{$key}"}
                : qq{'$body{$key}'};
            $body .= qq{ $key=$value};
        }
    }
    else { $body = $args_ref->{body}; }

    return qq{<body $body>};
}

################
# ORGANIZE_CSS #
################

sub _organize_css {
    my $args_ref = shift;

    my $css = exists $args_ref->{css} ? $args_ref->{css} : $CSS_DEF;
    if ( exists $args_ref->{no_css} ) { $css = $EMPTY; }

    # No 'x' on the match, please
    if ( $css =~ m{$NL}sm ) {

        # $css is data
        return qq{<style type="text/css">$NL} . qq{ <!--${css}--></style>$NL};
    }
    elsif ( $css ne $EMPTY ) {

        # $css is a file
        return qq{<link rel="stylesheet" href="$css" type="text/css">$NL};
    }
    return $EMPTY;
}

##################
# EVENT SUPPORT  #
##################

sub do_title {
    my $this = shift;
    my ( $txt, $a_name ) = @_;

    # This happens only on the _first_ head1 NAME
    if ( ( not exists $this->{TITLE} ) and ( $txt =~ m{\ANAME}smx ) ) {
        my ($title) = $txt =~ m{\ANAME\s+(.*)}smx;
        if ( defined $title ) {

            # Oh, goody
            $title =~ s{$RE{ws}{crop}}{}gsmx;  # delete surrounding whitespace
            $this->{TITLE} = $title;
        }
        else {

# If we don't get anything off of NAME, it will be filled in by preprocess_paragraph()
            $this->{TITLE} = undef;
        }
    }
    return;
}

##################
# DEFAULT EVENTS #
##################

sub evt_on_head1 {
    my $this = shift;
    my ( $txt, $a_name ) = @_;

    if ( not defined $txt ) { $txt = $EMPTY; }

    do_title( $this, $txt, $a_name );

    if ( exists $this->{UPARROW_FILE} ) {
        return qq{<h1><a href='#_top'
                 title='click to go to top of document' 
                 name='$a_name'>$txt<img src='$this->{UPARROW_FILE}'
                 alt=&uArr;></a></h1>$NL};
    }
    elsif ( exists $this->{UPARROW} ) {
        return qq{<h1><a href='#_top'
                  title='click to go to top of document' 
                  name='$a_name'>$txt&$this->{UPARROW};</a></h1>$NL};
    }

    return qq{<a name='$a_name'></a><h1>$txt</h1>$NL};
}

sub evt_on_head2 {
    my $this = shift;
    my ( $txt, $a_name ) = @_;
    return qq{<a name='$a_name'></a><h2>$txt</h2>$NL$NL};
}

sub evt_on_head3 {
    my $this = shift;
    my ( $txt, $a_name ) = @_;
    return qq{<a name='$a_name'></a><h3>$txt</h3>$NL$NL};
}

sub evt_on_head4 {
    my $this = shift;
    my ( $txt, $a_name ) = @_;
    return qq{<a name='$a_name'></a><h4>$txt</h4>$NL$NL};
}

sub evt_on_begin {
    my $this = shift;
    my ( $txt, $a_name ) = @_;
    $this->{IN_BEGIN} = 1;
    return $EMPTY;
}

sub evt_on_end {
    my $this = shift;
    my ( $txt, $a_name ) = @_;
    delete $this->{IN_BEGIN};
    return $EMPTY;
}

sub evt_on_L {
    my $this = shift;
    my ( $L, $text, $page, $section, $type ) = @_;

    if ( $type eq q{pod} ) {
        $section = defined $section ? qq{#$section} : $EMPTY;    # [6062]
            # Corrupt the href to avoid having it recognized (and converted) by _add_uri_href
        $text =~ s{\A(.)}{$1$NUL}smx;
        return
            defined $page
            ? qq{<i><a href='h${NUL}ttp://search.cpan.org/perldoc?$page$section'>$text</a></i>}
            : qq{<i><a href='$section'>$text</a></i>};    # Internal reference
    }
    elsif ( $type eq q{man} ) { return qq{<i>$text</i>}; }
    elsif ( $type eq q{url} ) {

# Corrupt the href to avoid having it recognized (and converted) by _add_uri_href
        $page =~ s{\A(.)}{$1$NUL}smx;
        $text =~ s{\A(.)}{$1$NUL}smx;
        return qq{<i><a href='$page' target='_blank'>$text</a></i>};
    }
}

sub evt_on_B {
    my $this = shift;
    my $txt  = shift;
    return qq{<b>$txt</b>};
}

sub evt_on_I {
    my $this = shift;
    my $txt  = shift;
    return qq{<i>$txt</i>};
}

sub evt_on_C {
    my $this = shift;
    my $txt  = shift;
    return qq{<font face='Courier New'>$txt</font>};
}

sub evt_on_E {
    my $this = shift;
    my $txt  = shift;

    $txt =~ s{^&}{}smx;
    $txt =~ s{;$}{}smx;
    if ( $txt =~ m{^\d+$}smx ) { $txt = qq{#$txt}; }
    return qq{&$txt;};
}

sub evt_on_F {
    my $this = shift;
    my $txt  = shift;
    return qq{<b><i>$txt</i></b>};
}

sub evt_on_S {
    my $this = shift;
    my $txt  = shift;
    $txt =~ s{$NL}{$SPACE}gsmx;
    return $txt;
}

sub evt_on_X { return $EMPTY; }    # [20078]

sub evt_on_Z { return $EMPTY; }

sub evt_on_verbatim {
    my $this = shift;
    my $txt  = shift;

    return if exists $this->{IN_BEGIN};

    # Multiple empty lines are parsed as verbatim text by Pod::Parser
    # And will show up as empty <pre> blocks, which is mucho messy
    {
        local $RS = $EMPTY;
        chomp $txt;
    }

    if ( not length $txt ) { return $EMPTY; }
    return qq{<pre>$txt</pre>$NL};
}

sub evt_on_textblock {
    my $this = shift;
    my $txt  = shift;
    return if exists $this->{IN_BEGIN};
    return qq{<p>$txt</p>$NL};
}

sub evt_on_over {
    my $this  = shift;
    my $level = shift;
    return qq{<ul>$NL};
}

sub evt_on_item {
    my $this = shift;
    my ( $txt, $a_name ) = @_;
    return qq{<li><a name='$a_name'></a><b>$txt</b></li>$NL};
}

sub evt_on_back {
    my $this = shift;
    return qq{</ul>$NL};
}

sub evt_on_for { return $EMPTY; }

sub evt_on_error {
    my $this = shift;
    my $txt  = shift;
    return qq{<!-- POD_ERROR: $txt -->};
}

sub evt_on_include {
    my $this = shift;
    my $file = shift;
    return $file;
}

sub evt_on_uri {
    my $this = shift;
    my $uri  = shift;
    my $target =
        $uri !~ m{^(?:mailto|telnet|ssh|irc):}ismx
        ? q{ target='_blank'}
        : $EMPTY;    # [6062]
    my $txt = $uri;
    $txt =~ s{^mailto:}{}ismx;
    return qq{<a href='$uri'$target>$txt</a>};
}

sub evt_on_index_node_start {
    my $this = shift;
    my ( $txt, $a_name, $has_children ) = @_;

    my $ret = qq{<li><a href='#$a_name'>$txt</a>$NL};
    if ($has_children) {
        $ret .= qq{$NL<ul>$NL};
    }
    return $ret;
}

sub evt_on_index_node_end {
    my $this = shift;
    my ( $txt, $a_name, $has_children ) = @_;

    my $ret = $has_children ? q{</ul>} : undef;
    return $ret;
}

##############
# PM_VERSION #
##############

sub pm_version {
    my $this = ref( $_[0] ) ? shift: undef;
    if ( not defined $this ) {
        carp q{pm_version must be referenced through Pod::HtmlEasy};
        return;
    }

    return $this->{VERSION};
}

##############
# PM_PACKAGE #
##############

sub pm_package {
    my $this = ref( $_[0] ) ? shift: undef;
    if ( not defined $this ) {
        carp q{pm_package must be referenced through Pod::HtmlEasy};
        return;
    }

    return $this->{PACKAGE};
}

###########
# PM_NAME #
###########

sub pm_name {
    my $this = ref( $_[0] ) ? shift: undef;
    if ( not defined $this ) {
        carp q{pm_name must be referenced through Pod::HtmlEasy};
        return;
    }
    return $this->{TITLE};
}

###########################
# PM_PACKAGE_VERSION_NAME #
###########################

sub pm_package_version_name {
    my $this = ref( $_[0] ) ? shift: undef;
    if ( not defined $this ) {
        carp
            q{pm_package_version_name must be referenced through Pod::HtmlEasy};
        return;
    }

    return ( $this->pm_package(), $this->pm_version(), $this->pm_name() );
}

#######
# END #
#######

1;

__END__

=pod

=head1 NAME

Pod::HtmlEasy - Generate easy and personalized HTML from PODs,
without extra modules and on "the flight".

=head1 VERSION

This documentation refers to Pod::HtmlEasy version 0.09.

=head1 DESCRIPTION

The purpose of this module is to generate HTML data from POD in a easy and personalized mode.

By default the HTML generated is similar to the CPAN site style for module documentation.

=head1 SYNOPSIS

Simple usage:

  my $podhtml = Pod::HtmlEasy->new() ;

  my $html = $podhtml->pod2html( 'test.pod' ) ;

  print "$html\n" ;

Complete usage:

  use Pod::HtmlEasy ;

  Create the object and set local events subs:

  Note that these are all the events, and examples of how to implement 
  them. All of these events are, of course, already implemented, so if
  the actions provided are adequate, no local subs are required.

  The actual implementation of on_head1 is somewhat more complex, to
  provide for the detection of the module title and insertion of the
  uparrow.

  my $podhtml = Pod::HtmlEasy->new (

  on_B         => sub {
                    my ( $this , $txt ) = @_ ;
                    return "<b>$txt</b>" ;
                  } ,

  on_C         => sub {
                    my ( $this , $txt ) = @_ ;
                    return "<font face='Courier New'>$txt</font>" ;
                  } ,

  on_E         => sub {
                    my ( $this , $txt ) = @_ ;
                    $txt =~ s{^&}{}smx;
                    $txt =~ s{;$}{}smx;
                    $txt = qq{#$txt} if $txt =~ /^\d+$/ ;
                    return qq{\0&$txt;};
                  } ,

  on_F         => sub {
                    my ( $this , $txt ) = @_ ;
                    return "<b><i>$txt</i></b>" ;
                  } ,

  on_I         => sub {
                    my ( $this , $txt ) = @_ ;
                    return "<i>$txt</i>" ;
                  } ,

  on_L         => sub {
                    my ( $this , $L , $text, $page , $section, $type ) = @_ ;
                    if   ( $type eq 'pod' ) {
		      $section = defined $section ? "#$section" : ''; 
		      $page = '' unless defined $page; 
                      return "<i><a href='http://search.cpan.org/perldoc?$page$section'>$text</a></i>" ;
                    }
                    elsif( $type eq 'man' ) { return "<i>$text</i>" ;}
                    elsif( $type eq 'url' ) { return "<a href='$page' target='_blank'>$text</a>" ;}
                  } ,

  on_S         => sub {
                    my ( $this , $txt ) = @_ ;
                    $txt =~ s/\n/ /gs ;
                    return $txt ;
                  } ,

  on_X         => sub { return '' ; } ,

  on_Z         => sub { return '' ; } ,

  on_back      => sub {
		    my $this = shift ;
		    return "</ul>$NL" ;
  		  } ,

  on_begin     => sub {
		    my $this = shift ;
		    my ( $txt , $a_name ) = @_ ;
		    $this->{IN_BEGIN} = 1;
		    return '';
  		  } ,

  on_error     => sub {
                    my ( $this , $txt ) = @_ ;
                    return qq{<!-- POD_ERROR: $txt -->} ;
                  } ,

  on_end       => sub { 
		    my $this = shift ;
		    my ( $txt , $a_name ) = @_ ;
		    delete $this->{IN_BEGIN};
		    return '';
                  } ,

  on_for       => sub { return '' ;} ,

  on_head1     => sub {
                    my ( $this , $txt , $a_name ) = @_ ;
                    return qq{<a name='$a_name'></a><h1>$txt</h1>$NL$NL} ;
                  } ,

  on_head2     => sub {
                    my ( $this , $txt , $a_name ) = @_ ;
                    return qq{<a name='$a_name'></a><h2>$txt</h2>$NL$NL} ;
                  } ,

  on_head3     => sub {
                    my ( $this , $txt , $a_name ) = @_ ;
                    return qq{<a name='$a_name'></a><h3>$txt</h3>$NL$NL} ;
                  } ,

  on_head4     => sub {
                    my ( $this , $txt , $a_name ) = @_ ;
                    return qq{<a name='$a_name'></a><h4>$txt</h4>$NL$NL} ;
                  } ,

  on_include   => sub {
                    my ( $this , $file ) = @_ ;
                    return qq{./$file} ;
                  } ,

  on_item      => sub {
                    my ( $this , $txt ) = @_ ;
                    return qq{<li>$txt</li>$NL} ;
                  } ,

  on_index_node_start => sub {
		    my ( $this , $txt , $a_name , $has_children ) = @_ ;
		    my $ret = qq{<li><a href='#$a_name'>$txt</a>$NL} ;
		    $ret .= q{$NL<ul>$NL} if $has_children ;
		    return $ret ;
		  } ,

  on_index_node_end => sub {
		    my $this = shift ;
		    my ( $txt , $a_name , $has_children ) = @_ ;
		    my $ret = $has_children ? q{</ul>} : $EMPTY ;
		    return $ret ;
		  } ,

  on_over      => sub {
                    my ( $this , $level ) = @_ ;
                    return qq{<ul>$NL? ;
                  } ,

  on_textblock => sub {
                    my ( $this , $txt ) = @_ ;
		    return if exists $this->{IN_BEGIN};
                    return qq{<p>$txt</p>$NL} ;
                  } ,

  on_uri       => sub {
                    my ( $this , $uri ) = @_ ;
                    return qq{<a href='$uri' target='_blank'>$uri</a>{ ;
                  } ,

  on_verbatim  => sub {
                    my ( $this , $txt ) = @_ ;
            $txt =~ s{(\A$NL)*(\A$NL)\z}{}gsmx;
		    return '' unless length $txt;
                    return qq{<pre>$txt</pre>$NL} ;
                  } ,
  ) ;

  ## Convert to HTML:

  my $html = $podhtml->pod2html('test.pod' ,
  				'test.html' ,
			        title => 'POD::Test' ,
			        body  => { bgcolor => '#CCCCCC' } ,
			        css   => 'test.css' ,
			       ) ;

=head1 SUBROUTINES/METHODS

=head2 new ( %EVENTS_SUBS )

By default the object has it own sub to handler the events.

But if you want to personalize/overwrite them you can set the keys in the initialization:

I<(For examples of how to implement the event subs see L<USAGE> above).>

=over 10

=item on_B ( $txt )

When I<B>I<<>I<...>I<>> is found. I<(bold text).>

=item on_C ( $txt )

When I<C>I<<>I<...>I<>> is found. I<(code text).>

=item on_E ( $txt )

When I<E>I<<>I<...>I<>> is found. I<(a character escape).>

=item on_I ( $txt )

When I<I>I<<>I<...>I<>> is found. I<(italic text).>

=item on_L ( $L , $text, $page, $section, $type )

When I<L>I<<>I<...>I<>> is found. I<(Link).>

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

=item on_F ( $txt )

When I<F>I<<>I<...>I<>> is found. I<(used for filenames).>

=item on_S ( $txt )

When I<S>I<<>I<...>I<>> is found. I<(text contains non-breaking spaces).>

=item on_X ( $txt )

When I<X>I<<>I<...>I<>> is found. I<(a null (zero-effect) formatting code).>

=item on_Z ( $txt )

When I<Z>I<<>I<...>I<>> is found. I<(a null (zero-effect) formatting code).>

=item on_back 

When I<=back> is found.

=item on_begin

When I<=begin> is found.

By default everything from '=begin' to '=end' is ignored.

=item on_error ( $txt )

Called on POD syntax error occurrence.

=item on_head1 ( $txt , $a_name )

When I<=head1> is found.

=over 10

=item $txt

The text of the command.

=item $a_name

The text of the command filtered to be used as C<<a name="$a_name"></a>>.

=back

=item on_head2 ( $txt , $a_name )

When I<=head2> is found. See I<on_head1>.

=item on_head3 ( $txt , $a_name )

When I<=head3> is found. See I<on_head1>.

=item on_head4 ( $txt , $a_name )

When I<=head4> is found. See I<on_head1>.

=item on_for

When I<=for> is found.

I<By default '=for' is ignored.>

=item on_item ( $txt )

When I<=item foo> is found.

=item on_end

When I<=end> is found.
See '=begin' above.

=item on_include ( $file )

When I<=include> is found.
Should be used only to handle the localtion of the $file.

=item on_index_node_start ( $txt , $a_name , $has_children )

Called to build the INDEX. This is called when a node is start.
I<$has_children> can be used to know if the node has childs (sub-nodes).

=item on_index_node_end ( $txt , $a_name , $has_children )

Called to build the INDEX. This is called when a node ends.
I<$has_children> can be used to know if the node has childs (sub-nodes).

=item on_over ( $level )

When I<=over X> is found.

=item on_textblock ( $txt )

When normal text blocks are found.

=item on_uri ( $uri )

When an URI (URL, E-MAIL, etc...) is found.

=item on_verbatim ( $txt )

When VERBATIM data is found, trailing empty lines are deleted.

Note: This interface was previously called "on_verbatin".
That interface has been retained for backwards compatibility.

=back

=head2 pod2html ( POD_FILE|POD_DATA|FILEHANDLE, HTML_FILE, %OPTIONS )

Convert a POD to HTML. Returns the HTML data generated, as a string or as a
list, according to context.

=over 10

=item POD_FILE|POD_DATA|GLOB

The POD file (file path), data (SCALAR) or FILEHANDLE (GLOB, opened).

=item HTML_FILE I<(optional)>

The output HTML file path or FILEHANDLE.

=item %OPTIONS I<(optional)>

=over 10

=item basic_entities

Deprecated. 

=item body

The body values.

Examples:

  body => q`alink="#FF0000" bgcolor="#FFFFFF" link="#000000" text="#000000" vlink="#000066"` ,

  ## Or:

  body => { bgcolor => "#CCCCCC" , link => "#0000FF" } , ## This will overwrite only this 2 values,


I<Default: alink="#FF0000" bgcolor="#FFFFFF" link="#000000" text="#000000" vlink="#000066">

=item common_entities

Deprecated. 

=item css

Can be a css file HREF or the css data.

Examples:

  css => 'test.css',

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

Set the index data. If not set the index will be generated automatically, calling the event subs
I<on_index_node_start> and I<on_index_node_end>

=item index_item

If set, items will be added in the index.

=item no_css

If set do not use css.

=item no_index

If set, do not build and insert the index.

=item no_generator

If set, the meta GENERATOR tag won't be added.

=item only_content

If set only generate the HTML content (between <body>...</body>).

=item parserwarn

The backend we use is Pod::Parser. This module generates warnings when it detects
badly-formed POD. Regretably, it also generates warnings about multiple blank lines,
which can be annoying. Thus, it's disabled by default.

=item title

The title of the HTML.
I<Default: content of the first =head1 NAME, or, failing that the file path>

=item top

Set TOP data. The HTML I<_top> will be added just before the I<index>.
If there is a value associated with -top (as in -top uArr)
That value will be added to to the head1 text. The value should be
either a literal character, a representation of a extended HTML character,
(as in uArr) or an I<existing> file.

=back

=back

=head1 Utility Functions

=head2 default_css

Returns the default CSS.

=head2 pm_version ( pod2html )

Return the version of a Perl module file or I<undef>.
This is extracted from a statement that looks like "VERSION = 5.0008"

=head2 pm_package ( pod2html )

Return the package name of a Perl module file or I<undef>.

=head2 pm_name ( pod2html )

Returns what follows the first instance of 
I<=head1 NAME> description or I<undef>.

=head2 pm_package_version_name ( pod2html )

Returns a list: ( pm_package, pm_version,  pm_name )

=head1 CHARACTER SET

In compliance with L<HTML 4.01 specification|http://www.w3.org/TR/html4/>, Pod::HtmlEasy supports
the ISO 8859-1 character set (also known as Latin-1). In essence, this means that the full
8-bit character set is supported.

HTML provides an escape mechanism that allows characters to be specified by name; this kind of
specification is called an I<entity>.

Some characters must be converted to entities to avoid confusing user agents. This happens 
automagically. These characters are: &, <, >, "

HTML (via its relationship with SGML) supports a large number of characters that are 
outside the set supported by ISO 8859-1. These can be specified in the text by using
the E&ls;...&gt; construct. These encodings are defined by ISO 10646, which is semi-informally
known as UNICODE. http://www.unicode.org/Public/5.0.0/ucd/UCD.html.  For example, 
the "heart" symbol E&l;dhearts&gt;.
These are listed in section 24.3.1,
L<The list of characters|http://www.w3.org/TR/html4/sgml/entities.html#h-24.4.1>
of the HTML 4.01 specification.

=head1 EMBEDDED URIs

Pod::HtmlEasy scans text (but not verbatim text!) for embedded URIs, such as C<http://foo.bar.com>
that are I<not> embedded in L&ls;...&gt. Schemes detected are http, https, file and ftp. References
of the form foo@bar.com are treated as mailto references and are translated accordingly.

Previous versions handled a more extensive list of URIs. It was thought that the overhead for
processing these other schemes was not justified by their utility.

=head1 EXTENDING POD

You can extend POD defining non-standard events.

For example, to enable the command I<"=hr">:

  my $podhtml = Pod::HtmlEasy->new(
  on_hr => sub {
            my ( $this , $txt ) = @_ ;
            return "<hr>" ;
           }
  ) ;

To define a new formatting code, do the same thing, but the code must be a single letter.

So, to enable I<"G>I<<...>I<>>I<">:

  my $podhtml = Pod::HtmlEasy->new(
  on_G => sub {
            my ( $this , $txt ) = @_ ;
            return "<img src='$txt' border=0>" ;
          }
  ) ;

=head1 DEPENDENCIES

This script requires the following modules:

 L<Pod::HtmlEasy::Parser>
 L<Pod::HtmlEasy::TiehHandler>

 L< Carp>
 L< English>
 L< File::Slurp>
 L< Readonly>
 L< Regexp::Common>
 L< Switch>

=head1 DEFAULT CSS

This is the default CSS added to the HTML.

I<** If you will set your own CSS use this as base.>

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

=head1 DIAGNOSTICS

=over 10

=item option I<key> is not supported

You've used (mis-spelled?) an unrecognized option.

=item "basic_entities" is deprecated

Like it says.

=item "common_entities" is deprecated

Like it says.

=item No file I<file>

We couldn't find that (input) file.

=item pm_I<whatever> must be referenced through Pod::HtmlEasy

The various pm_ functions are referenced through the module.

The maintainer would appreciate hearing about
any messages I<other> than those that result from
the C<use warnings> specified for each module. .

HtmlEasy uses Pod::Parser, which may produce error messages concerning malformed
HTML.

=head1 SEE ALSO

L<Pod::Parser> L<perlpod>.

=head1 CONFIGURATION AND ENVIRONMENT

Neither is relevant.

=head1 INCOMPATIBILITIES

None are known.

=head1 BUGS AND LIMITATIONS

Please report problems at RT: L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Pod-HtmlEasy>

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

Thanks to Ivan Tubert-Brohman <itub@cpan.org> that suggested to add the basic_entities
and common_entities options and for tests.

=head1 MAINTENANCE

Updates for version 0.0803 and subsequent by Geoffrey Leach <gleach@cpan.org>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

