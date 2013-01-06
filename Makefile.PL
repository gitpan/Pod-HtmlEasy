###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;
use English qw{ -no_match_vars };

WriteMakefile(
    'NAME'          => 'Pod::HtmlEasy' ,
    'VERSION_FROM'  => 'lib/Pod/HtmlEasy.pm' ,
    'PREREQ_PM'     => {
                        'Carp'           => 0,
                        'English'        => 0,
                        'Exporter::Easy' => 0.16,
                        'File::Slurp'    => 9999.13,
                        'IPC::Run'       => 0.80,
                        'Pod::Escapes'   => 1.04,
                        'Pod::Parser'    => 2.3.1,
                        'Pod::ParseLink' => 1.06,
                        'Readonly'       => 1.03,
                        'Regexp::Common' => 2.120,
                        'Pod::ParseLink' => 1.06,
                        'Regexp::Common::Email::Address' => 1.01,
                         ($PERL_VERSION >= 5.012 ? (
                                 'feature'        => 1.16,
                         ) : (
                                 'Switch'         => 2.13,
                         )),
                        'Test::More'     => 0.94,
                        'version'        => 0.82,
                       } ,
    'EXE_FILES'     => [ qw(
                            scripts/podhtmleasy.pl
                            scripts/debug.pl
                            scripts/pod2indexed_html.pl
                            scripts/podhtmleasy.sh
                            ) ],
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Pod/HtmlEasy.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>, Geoffrey Leach <gleach@cpan.org>'
       ) : ()
     ),
);

1;
