#! /usr/bin/perl

use Test;
BEGIN { plan tests => 4 }

use Pod::HtmlEasy;
use File::Slurp;

use strict;
use warnings;

# An example of the definition of a non-standard formatting code
my $podhtml = Pod::HtmlEasy->new(
    on_G => sub {
        my ( $this, $txt ) = @_;
        $txt .= ".jpg" if $txt !~ /\.(?:jpg|gif|png)$/i;
        return "<img src='$txt' border=0>";
    }
);

my $test_dir = './tests';
my @files = read_dir("$test_dir");

foreach my $files_i ( sort @files ) {

    next if $files_i !~ s/\.pod$//;
    my $pod_file  = "$test_dir/$files_i.pod";
    my $html_file = "$test_dir/$files_i.html";

    my $html;
    if ( !-r $html_file ) {
        ## A wee hack to generate the HTMLs
        $podhtml->pod2html(
            $pod_file, $html_file,
            index_item   => 1,
            no_generator => 1,
            top          => 'uArr',
        );
        next;
    }
    else {
        $html = $podhtml->pod2html(
            $pod_file,
            index_item   => 1,
            no_generator => 1,
            top          => 'uArr',
        );
    }

    my $chk_html = read_file($html_file);

    if ( $html eq $chk_html ) { ok(1); }
    else {
        ok(0);
        write_file( "${html_file}.fail", $html );
        # Produces an un-helpful message. Sorry!
        # Enable this to see what's gone wrong.`
        # system("diff $html_file ${html_file}.fail);`
    }
}

