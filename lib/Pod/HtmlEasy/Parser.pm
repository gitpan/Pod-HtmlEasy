#############################################################################
## Name:        Parser.pm
## Purpose:     Pod::HtmlEasy::Parser
## Author:      Graciliano M. P.
## Modified by: Geoffrey Leach
## Created:     11/01/2004
## Updated:	    2007-02-25
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Pod::HtmlEasy::Parser;

use base qw{ Pod::Parser };
use Pod::Parser;

use Carp;
use English qw{ -no_match_vars };
use Readonly;
use Regexp::Common qw{ whitespace number URI };
use Switch qw{ Perl6 };

use strict;
use warnings;

our $VERSION = 0.04;

my ( $EMPTY, $NL, $NUL, $SPACE );
Readonly::Scalar $EMPTY => q{};
Readonly::Scalar $NL    => qq{\n};
Readonly::Scalar $NUL   => qq{\0};
Readonly::Scalar $SPACE => q{ };

########
# VARS #
########

my $MAIL_RE = qr{
         (         # grab all of this
         [\w-]+    # some word chars with '-' included   foo
         \0?       # possible NUL escape
         \@        # literal '@'                         @
         [\w\\-]+  # another word                        bar
         (?:       # non-grabbing pattern
          \.       # literal '.'                        .
          [\w\-\.]+# that word stuff                    stuff
          \.       # another literal '.'                .
          [\w\-]+  # another word                       and
          |        # or
          \.       # literal '.'                        .   
          [\w\-]+  # word                               nonsense
          |        # or empty?
         )        # end of non-grab
         )        # end of grab
        }smx;    # [6062]

# Treatment of embedded HTML-significant characters and embedded URIs.

# There are some characters (%html_entities below) which may in some
# circumstances be interpreted by a browser, and you probably don't want that
# Consequently, they are replaced by names defined by the W3C UNICODE spec,
# http://www.w3.org/TR/MathML2/bycodes.html, bracketed by '&' and ';'
# Thus, '>' becomes '&lt;' This is handled by _encode_entities()
# There's a "gotchya" in this process. As we are generating HTML,
# the encoding needs to take place _before_ any HTML is generated.

# If the HTML appears garbled, and UNICODE entities appear where they
# shouldn't, this encoding has happened to late at some point.

# This is all further complicated by the fact that the POD formatting
# codes syntax uses some of the same characters, as in "L<...>", for example,
# and we can't expand those first, because some of them generate
# HTML. This is resolved by tagging the characters that we want
# to distinguish from HTML with ASCII NUL ('\0', $NUL). Thus, '$lt;' becomes
# '\0&amp;' in _encode_entities().  Generated HTML is also handled
# this way by _nul_escape(). After all processing of the  POD formatting
# codes are processed, this is reversed by _remove _nul_escapes().

# Then there's the issue of embedded URIs. URIs are also generated
# by the processing of L<...>, and can show up _inside L<...>, we
# delay processing of embedded URIs until after all of the POD
# formatting codes is complete. URIs that result from that processing
# are tagged (you guessed it!) with a NUL character, but not preceeding
# the generated URI, but after the first character. These NULs are removed
# by _remove _nul_escapes()

my %html_entities = (
    q{&} => q{amp},
    q{>} => q{gt},
    q{<} => q{lt},
    q{"} => q{quot},
);

my $HTML_ENTITIES_RE = join q{|}, keys %html_entities;
$HTML_ENTITIES_RE = qr{$HTML_ENTITIES_RE};

#################
# _NUL_ESCAPE   #
#################

# Escape HTML-significant characters with ASCII NUL to differentiate them
# from the same characters that get converted to entity names

sub _nul_escape {
    my $txt_ref = shift;

    ${$txt_ref} =~ s{($HTML_ENTITIES_RE)}{$NUL$1}gsmx;
    return;
}

#######################
# _REMOVE_NUL_ESCAPSE #
#######################

sub _remove_nul_escapes {
    my $txt_ref = shift;

    ${$txt_ref} =~ s{$NUL}{}gsmx;
    return;
}

####################
# _ENCODE_ENTITIES #
####################

sub _encode_entities {
    my ( $parser, $txt_ref ) = @_;

    foreach my $chr ( keys %html_entities ) {

        # $chr gets a lookbehind to avoid converting flagged from E<...>
        my $re = qq{(?<!$NUL)$chr};
        ${$txt_ref} =~ s{$re}{$NUL&$html_entities{$chr};}gsmx;
    }

    return;
}

#################
# _ADD_URI_HREF #
#################

# process embedded URIs that are not noted in l<...> bracketing
# Note that the HTML-significant characters are escaped;
# The escapes are removed by _encode_entities

sub _add_uri_href {
    my ( $parser, $txt_ref ) = @_;

    if ( ${$txt_ref} eq $EMPTY ) { return ${$txt_ref}; }

    if ( ${$txt_ref} =~ m{https?:}smx ) {
        ${$txt_ref}
            =~ s{$RE{URI}{HTTP}{-keep}{-scheme=>'https?'}}{<a href='$1'</a>}gsmx;
    }
    if ( ${$txt_ref} =~ m{ftp:}smx ) {
        ${$txt_ref} =~ s{$RE{URI}{FTP}{-keep}}{<a href='$1'</a>}gsmx;
    }
    if ( ${$txt_ref} =~ m{file:}smx ) {
        ${$txt_ref} =~ s{$RE{URI}{file}{-keep}}{<a href='$1'</a>}gsmx;
    }
    if ( ${$txt_ref} =~ m{$MAIL_RE}smx ) {
        ${$txt_ref} =~ s{($MAIL_RE)}{<a href='mailto:$1'>$1</a>}gsmx;
    }

    return;
}

###########
# COMMAND #
###########

# Overrides command() provided by base class in Pod::Parser
sub command {
    my ( $parser, $command, $paragraph, $line_num, $pod ) = @_;

    if ( defined $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER} ) {
        _verbatim($parser);
    }    # [6062]

    my $expansion = $parser->interpolate( $paragraph, $line_num );

    $expansion =~ s{$RE{ws}{crop}}{}gsmx;    # delete surrounding whitespace

    # Encoding puts in a NUL; we're finished with the text, so remove them
    _encode_entities( $parser, \$expansion );
    _remove_nul_escapes( \$expansion );

# Create the index tag
# a_name has the text of the expansion _without_ anything between '<' and '>',
# which amounts to the HTML formatting codes, which are not processed by
# the name directive.
    my $a_name = $expansion;
    $a_name =~ s{<.*?>}{}gsmx;

    my $html;
    given ($command) {
        when q{head1} {
            _add_tree_point( $parser, $expansion, 1 );
            $html = $parser->{POD_HTMLEASY}
                ->{ON_HEAD1}( $parser->{POD_HTMLEASY}, $expansion, $a_name );
        }
        when q{head2} {
            _add_tree_point( $parser, $expansion, 2 );
            $html = $parser->{POD_HTMLEASY}
                ->{ON_HEAD2}( $parser->{POD_HTMLEASY}, $expansion, $a_name );
        }
        when q{head3} {
            _add_tree_point( $parser, $expansion, 3 );
            $html = $parser->{POD_HTMLEASY}
                ->{ON_HEAD3}( $parser->{POD_HTMLEASY}, $expansion, $a_name );
        }
        when q{head4} {
            _add_tree_point( $parser, $expansion, 4 );
            $html = $parser->{POD_HTMLEASY}
                ->{ON_HEAD4}( $parser->{POD_HTMLEASY}, $expansion, $a_name );
        }
        when q{begin} {
            _add_tree_point( $parser, $expansion, 4 );
            $html = $parser->{POD_HTMLEASY}
                ->{ON_BEGIN}( $parser->{POD_HTMLEASY}, $expansion, $a_name );
        }
        when q{end} {
            $html = $parser->{POD_HTMLEASY}
                ->{ON_END}( $parser->{POD_HTMLEASY}, $expansion, $a_name );
        }
        when q{over} {
            if ( $parser->{INDEX_ITEM} ) {
                $parser->{INDEX_ITEM_LEVEL}++;
            }
            $html = $parser->{POD_HTMLEASY}
                ->{ON_OVER}( $parser->{POD_HTMLEASY}, $expansion );
        }
        when q{item} {
            if ( $parser->{INDEX_ITEM} ) {
                _add_tree_point( $parser, $expansion,
                    ( 3 + ( $parser->{INDEX_ITEM_LEVEL} || 1 ) ) );
            }
            $html = $parser->{POD_HTMLEASY}
                ->{ON_ITEM}( $parser->{POD_HTMLEASY}, $expansion, $a_name );
        }
        when q{back} {
            if ( $parser->{INDEX_ITEM} ) {
                $parser->{INDEX_ITEM_LEVEL}--;
            }
            $html = $parser->{POD_HTMLEASY}
                ->{ON_BACK}( $parser->{POD_HTMLEASY}, $expansion );
        }
        when q{for} {
            $html = $parser->{POD_HTMLEASY}
                ->{ON_FOR}( $parser->{POD_HTMLEASY}, $expansion, $a_name );
        }
        when q{include} {
            my $file = $parser->{POD_HTMLEASY}
                ->{ON_INCLUDE}( $parser->{POD_HTMLEASY}, $expansion );
            if (   -e $file
                && -r $file )
            {
                $parser->{POD_HTMLEASY}->parse_include($file);
            }
        }
        default {
            if ( defined $parser->{POD_HTMLEASY}->{qq{ON_\U$command\E}} ) {
                $html = $parser->{POD_HTMLEASY}
                    ->{qq{ON_\U$command\E}}( $parser->{POD_HTMLEASY},
                    $expansion );
            }
            elsif ( $command !~ /^(?:pod|cut)$/imx ) {
                $html = qq{<pre>=$command $expansion</pre>};
            }
            else { $html = $EMPTY; }
        }
    };

    if ( $html ne $EMPTY ) {
        print { $parser->output_handle() } $html;
    }    # [6062]

    return;
}

############
# VERBATIM #
############

# Overrides verbatim() provided by base class in Pod::Parser
sub verbatim {
    my ( $parser, $paragraph, $line_num ) = @_;

    if ( exists $parser->{POD_HTMLEASY}->{IN_BEGIN} ) { return; }
    $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER} .= $paragraph;

    return;
}

sub _verbatim {
    my ($parser) = @_;

    if ( exists $parser->{POD_HTMLEASY}->{IN_BEGIN} ) { return; }
    my $expansion = $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER};
    $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER} = $EMPTY;

    _encode_entities( $parser, \$expansion );

    my $html = $parser->{POD_HTMLEASY}
        ->{ON_VERBATIM}( $parser->{POD_HTMLEASY}, $expansion );

    # Now look for any embedded URIs
    _add_uri_href( $parser, \$html );

    # And remove any NUL escapes
    _remove_nul_escapes( \$html );

    if ( $html ne $EMPTY ) {
        print { $parser->output_handle() } $html;
    }    # [6062]

    return;
}

#############
# TEXTBLOCK #
#############

# Overrides textblock() provided by base class in Pod::Parser
sub textblock {
    my ( $parser, $paragraph, $line_num ) = @_;

    if ( exists $parser->{POD_HTMLEASY}->{IN_BEGIN} ) { return; }
    if ( defined $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER} ) {
        _verbatim($parser);
    }    # [6062]

    my $expansion = $parser->interpolate( $paragraph, $line_num );

    $expansion =~ s{$RE{ws}{crop}}{}gsmx;    # delete surrounding whitespace
    $expansion =~ s{\s+$}{}gsmx;

    # Encode HTML-specific characters before adding any HTML (eg <p>)
    _encode_entities( $parser, \$expansion );

    my $html = $parser->{POD_HTMLEASY}
        ->{ON_TEXTBLOCK}( $parser->{POD_HTMLEASY}, $expansion );

    # Now look for any embedded URIs
    _add_uri_href( $parser, \$html );

    # And remove any NUL escapes
    _remove_nul_escapes( \$html );

    if ( $html ne $EMPTY ) { print { $parser->output_handle() } $html; }

    return;
}

#####################
# INTERIOR_SEQUENCE #
#####################

# Overrides interior_sequence() provided by base class in Pod::Parser
sub interior_sequence {
    my ( $parser, $seq_command, $seq_argument, $pod_seq ) = @_;

    my $ret;

    given ($seq_command) {
        when q{B} {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_B}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when q{C} {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_C}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when q{E} {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_E}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when q{F} {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_F}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when q{I} {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_I}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when q{L} {
            my ( $text, $name, $section, $type ) = _parselink($seq_argument);
            $ret = $parser->{POD_HTMLEASY}->{ON_L}(
                $parser->{POD_HTMLEASY},
                $seq_argument, $text, $name, $section, $type
            );
        }
        when q{S} {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_S}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when q{Z} {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_Z}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        default {
            if ( defined $parser->{POD_HTMLEASY}->{qq{ON_\U$seq_command\E}} )
            {
                $ret = $parser->{POD_HTMLEASY}
                    ->{qq{ON_\U$seq_command\E}}( $parser->{POD_HTMLEASY},
                    $seq_argument );
            }
            else {
                $ret = qq{$seq_command<$seq_argument>};
            }
        }
    }

    # Escape HTML-significant characters
    _nul_escape( \$ret );

    return $ret;
}

########################
# PREPROCESS_PARAGRAPH #
########################

# Overrides preprocess_paragraph() provided by base class in Pod::Parser
# NB: the text is _not altered.
sub preprocess_paragraph {
    my $parser = shift;
    my ( $text, $line_num ) = @_;

    if ( $parser->{POD_HTMLEASY}{INFO_COUNT} == 3 ) {
        return $text;
    }

    if ( not exists $parser->{POD_HTMLEASY}{PACKAGE} ) {
        if ( $text =~ m{package}smx ) {
            my ($pack) = $text =~ m{(\w+(?:::\w+)*)}smx;
            if ( defined $pack ) {
                $parser->{POD_HTMLEASY}{PACKAGE} = $pack;
                $parser->{POD_HTMLEASY}{INFO_COUNT}++;
            }
        }
    }

    if ( not exists $parser->{POD_HTMLEASY}{VERSION} ) {
        if ( $text =~ m{VERSION}smx ) {
            my ($ver) = $text =~ m{($RE{num}{decimal})}smx;
            if ( defined $ver ) {
                $parser->{POD_HTMLEASY}{VERSION} = $ver;
                $parser->{POD_HTMLEASY}{INFO_COUNT}++;
            }
        }
    }

    # This situation is created by evt_on_head1()
    if (    ( exists $parser->{POD_HTMLEASY}{TITLE} )
        and ( not defined $parser->{POD_HTMLEASY}{TITLE} ) )
    {
        my @lines = split m{\n}smx, $text;
        my $tmp_text = shift @lines;
        if ( not defined $tmp_text ) { return $text; }
        $tmp_text =~ s{$RE{ws}{crop}}{}gsmx;   # delete surrounding whitespace
        $parser->{POD_HTMLEASY}{TITLE} = $tmp_text;
        $parser->{POD_HTMLEASY}{INFO_COUNT}++;
    }

    return $text;
}

##################
# _PARSE_SECTION #
##################

# Parse a link that is not a URL to get the name and/or section
# Algorithm may be found in perlpodspec. "About L<...> Codes"

sub _parse_section {
    my $link = shift;
    $link =~ s{$RE{ws}{crop}}{}gsmx;    # delete surrounding whitespace

    # L<"FooBar"> is a the way to specify a section without a name.
    # However, L<Foo Bar> is possible, though deprecated. See below.
    if ($link =~ m{
                    \A          # beginning at the beginning
                    "           # literal "
                   }smx
        )
    {
        $link =~ s{"}{}gsmx;                # strip the "s
        $link =~ s{$RE{ws}{crop}}{}gsmx;    # and leading/trailing whitespace
        return ( undef, $link );
    }

    # So now we have either a name by itself, or name/section
    my ( $name, $section ) = split m{/}smx, $link, 2;

    # Trim leading and trailing whitespace and quotes from section
    $name =~ s{$RE{ws}{crop}}{}gsmx;
    if ($section) {
        $section =~ s{$RE{ws}{crop}}{}gsmx;    # leading/trailing
        $section =~ s{"}{}gsmx;                # quotes
        $section =~ s{$RE{ws}{crop}}{}gsmx;
    }    # new leading/trailing

# Perlpodspec observes that and acceptable way to distinguish between L<name> and
# L<section> is that if the link contains any whitespace, then its a section.
# The construct L<section> is deprecated.
    if ( $name && $name =~ m{\s}smx && !defined $section ) {
        $section = $name;
        $name    = undef;
    }

    return ( $name, $section );
}

###############
# _INFER_TEXT #
###############

# Infer the text content of a L<...> with no text| part (ie a text|-less link)
# By definition (?) either name or section is nonempty, Algorithm from perlpodspec

sub _infer_text {
    my ( $name, $section ) = @_;

    if ($name) {
        return $section
            ? q{"} . $section . q{"} . q{ in } . $name
            : $name;
    }

    return q{"} . $section . q{"};
}

##############
# _PARSELINK #
##############

# Parse the content of L<...> and return
#   The text label
#   The name or URL
#   The section (if relevant)
#   The type of link discovered: url, man or pod

sub _parselink {
    my $link = shift;
    my $text;

    # Squeeze out multiple spaces
    $link =~ s{\s+}{$SPACE}gsmx;

    if ( $link =~ m{\|}smx ) {

        # Link is in the form "L<Foo|Foo::Bar>"
        ( $text, $link ) = split m{\|}smx, $link, 2;
    }

# Check for a generalized URL. The regex is defined in perlpodspec.
# Quoting perlpodspec: "Authors wanting to link to a particular (absolute) URL, must do so
# only with "L<scheme:...>" codes and must not attempt "L<Some Site Name|scheme:...>"
# Consequently, although $text might be nonempty, we ignore it.
    if ($link =~ m{
                    \A      # The beginning of the string
                    \w+     # followed by some alphanumerics, which would be the protocol (or scheme)
                    :       # literal ":"
                    [^:\s]  # one char that is neither a ":" or whitespace
                    \S*     # maybe some non-whitespace
                    \z      # the end of the string
                   }smx
        )
    {
        return ( $link, $link, undef, q{url} );
    }

    # OK, we've eliminated URLs, so we must be dealing with something else

    my ( $name, $section ) = _parse_section($link);
    if ( not defined $text ) { $text = _infer_text( $name, $section ); }

# A link with parenthesized non-whitespace is assumed to be a manpage reference
# (per perlpodspec))
    my $type =
        ( $name && $name =~ m{\(\S*\)}smx )
        ? q{man}
        : q{pod};

    return ( $text, $name, $section, $type );
}

###################
# _ADD_TREE_POINT #
###################

sub _add_tree_point {
    my ( $parser, $name, $level ) = @_;
    $level ||= 1;

    if ( $level == 1 ) {
        $parser->{POD_HTMLEASY}->{INDEX}{p}
            = $parser->{POD_HTMLEASY}->{INDEX}{tree};
    }
    else {
        if ( exists $parser->{POD_HTMLEASY}->{INDEX}{p} ) {
            while ( $parser->{POD_HTMLEASY}
                ->{INDEX}{l}{ $parser->{POD_HTMLEASY}->{INDEX}{p} }
                > ( $level - 1 ) )
            {
                last
                    if !$parser->{POD_HTMLEASY}
                    ->{INDEX}{b}{ $parser->{POD_HTMLEASY}->{INDEX}{p} };
                $parser->{POD_HTMLEASY}->{INDEX}{p} = $parser->{POD_HTMLEASY}
                    ->{INDEX}{b}{ $parser->{POD_HTMLEASY}->{INDEX}{p} };
            }
        }
    }

    my $array = [];

    $parser->{POD_HTMLEASY}->{INDEX}{l}{$array} = $level;
    $parser->{POD_HTMLEASY}->{INDEX}{b}{$array}
        = $parser->{POD_HTMLEASY}->{INDEX}{p};

    push @{ $parser->{POD_HTMLEASY}->{INDEX}{p} }, $name, $array;
    $parser->{POD_HTMLEASY}->{INDEX}{p} = $array;

    return;

}

#############
# BEGIN_POD #
#############

# Overrides begin_pod() provided by base class in Pod::Parser
sub begin_pod {
    my ($parser) = @_;

    if ( $parser->{POD_HTMLEASY_INCLUDE} ) { return; }

    delete $parser->{POD_HTMLEASY}->{INDEX};
    $parser->{POD_HTMLEASY}->{INDEX} = { tree => [] };

    return 1;
}

###########
# END_POD #
###########

# Overrides end_pod() provided by base class in Pod::Parser
sub end_pod {
    my ($parser) = @_;

    if ( $parser->{POD_HTMLEASY_INCLUDE} ) { return; }

    if ( defined $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER} ) {
        _verbatim($parser);
    }

    my $tree = $parser->{POD_HTMLEASY}->{INDEX}{tree};

    delete $parser->{POD_HTMLEASY}->{INDEX};

    $parser->{POD_HTMLEASY}->{INDEX} = $tree;

    return 1;
}

###########
# _ERRORS #
###########

sub _errors {
    my ( $parser, $error ) = @_;

    carp "$error";
    $error =~ s{^\s*\**\s*errors?:?\s*}{}ismx;
    $error =~ s{\s+$}{}smx;

    my $html = $parser->{POD_HTMLEASY}
        ->{ON_ERROR}( $parser->{POD_HTMLEASY}, $error );
    if ( $html ne $EMPTY ) {
        print { $parser->output_handle() } $html, $NL;
    }

    return 1;
}

###########
# DESTROY #
###########

sub DESTROY { }

#######
# END #
#######

1;

