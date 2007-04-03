###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Pod::HtmlEasy' ,
    'VERSION_FROM'  => 'lib/Pod/HtmlEasy.pm' ,
    'PREREQ_PM'     => {'Pod::Parser'    => 0,
                        'File::Slurp'    => 0,
                        'Carp'           => 0,
                        'English'        => 0,
                        'Readonly'       => 0,
                        'Regexp::Common' => 0,
                        'Pod::Parser'    => 0,
                        'Switch'         => 0,
                       } ,
    'EXE_FILES'     => [ qw(script/podhtmleasy.pl) ],
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Pod/HtmlEasy.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>, Geoffrey Leach <gleach@cpan.org>'
       ) : ()
     ),
);

1;

