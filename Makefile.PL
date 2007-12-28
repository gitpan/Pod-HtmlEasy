###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Pod::HtmlEasy' ,
    'VERSION_FROM'  => 'lib/Pod/HtmlEasy.pm' ,
    'PREREQ_PM'     => {'Carp'           => 0,
                        'English'        => 0,
                        'File::Slurp'    => 9999.12,
                        'Pod::Parser'    => 1.13,
                        'Readonly'       => 1.03,
                        'Regexp::Common' => 2.120,
                        'Switch'         => 2.13,
                       } ,
    'EXE_FILES'     => [ qw(script/podhtmleasy.pl) ],
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Pod/HtmlEasy.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>, Geoffrey Leach <gleach@cpan.org>'
       ) : ()
     ),
);

1;

