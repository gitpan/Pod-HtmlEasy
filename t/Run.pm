#
#===============================================================================
#
#         FILE:  Run.pm
#
#  DESCRIPTION:  Function to run individual tests
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach, <geoff@hughes.net>
#      VERSION:  1.0
#      CREATED:  12/20/07 13:29:02 PST
#     REVISION:  ---
#===============================================================================

package Run;
use 5.006002;

use strict;
use warnings;

use Carp;
use English qw{ -no_match_vars };
use File::Slurp;
use Readonly;
use Test::More qw(no_plan);
use version; our $VERSION = qv('1.0'); # Also appears in "=head1 VERSION" in the POD below

BEGIN {
    use_ok(q{Pod::HtmlEasy});
    use_ok( q{Pod::HtmlEasy::Data},
        qw( EMPTY NL body css gen head headend title toc top podon podoff ) );
}

use Exporter qw( import );
our @EXPORT_OK = qw( run html_file );

my $pod_file  = q{./test.pod};
my $html_file = q{./test.html};
my $htmleasy  = Pod::HtmlEasy->new;
ok( defined $htmleasy, q{New HtmlEasy} );

Readonly::Scalar my $LAST_OK => 3;
my ($test_id) = $PROGRAM_NAME =~ m{(\w+)\.t\Z}smx;
my $test_no = $LAST_OK;

my %default_opts = (
    no_css       => 1,
    title        => $html_file,
    no_generator => 1,
);

sub run {
    my ( $desc, $pod, $expect, $inx, $opts ) = @_;

    $test_no++;
    my $test = sprintf q{%s-%02d.html}, $test_id, $test_no;

    # If $pod is undef we test against empty input
    my @pod;
    if ( defined $pod ) {

        # EMPTY becomes an empty line when NL is mapped in below
        @pod = ( q{=pod}, EMPTY );

        push @pod, map { ( $_, EMPTY ) } @{$pod};
        push @pod, q{=cut};
        @pod = map { $_ . NL } @pod;
    }
    write_file( $pod_file, \@pod );
    if ( not defined $opts ) { $opts = \%default_opts; }
    if ( not exists $opts->{title} ) {
        $opts->{title} = $default_opts{title};
    }
    if ( exists $opts->{htmleasy} ) {

        # Alert: $htmleasy is now not what it was originally defined
        $htmleasy = $opts->{htmleasy};
        delete $opts->{htmleasy};
    }
    my @html;
    if ( exists $opts->{outfile} ) {

        # Outfile is for this;
        my $outfile = $opts->{outfile};
        delete $opts->{outfile};
        @html = $htmleasy->pod2html( $pod_file, $outfile, %{$opts} );
    }
    else {
        @html = $htmleasy->pod2html( $pod_file, %{$opts} );
    }
    if ( defined $expect ) {
        my @expect;
        if ( not $opts->{only_content} ) {
            @expect = head();
            if ( not exists $opts->{no_generator} ) {
                push @expect,
                    gen( $Pod::HtmlEasy::VERSION, $Pod::Parser::VERSION );
            }
            push @expect, title( $opts->{title} );
            if ( exists $opts->{css} ) {
                push @expect, css( $opts->{css} );
            }
            else {
                if ( not exists $opts->{no_css} ) { push @expect, css(); }
            }
            push @expect, headend();
            push @expect, body( $opts->{body} );
        }
        if ( exists $opts->{top} )          { push @expect, top(); }
        if ( not exists $opts->{no_index} ) { push @expect, toc( @{$inx} ); }
        push @expect, podon();
        push @expect, @{$expect};
        push @expect, podoff( exists $opts->{only_content} ? 1 : undef );
        @expect = map { $_ . NL } @expect;
        if ( not is_deeply( \@html, \@expect, $desc ) ) {
            print qq{POD input $test}, NL, @pod, NL,
                qq{Expected output $test}, NL, @expect, NL,
                qq{Actual output $test}, NL, @html
                or carp q{Unable to print output html};
        }
    }
    else {
        print qq{Actual output $test}, NL, @html
            or carp q{Unable to print output html};
    }

    if ( exists $ENV{DUMPHTML} ) { write_file( $test, \@html ); }
    unlink $pod_file, $html_file;
    return;
}

sub html_file { return $html_file; }

1;
