###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Pod::HtmlEasy' ,
    'VERSION_FROM'  => 'lib/Pod/HtmlEasy.pm' ,
    'PREREQ_PM'     => {'Pod::Parser' => 1.12} ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Pod/HtmlEasy.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>'
       ) : ()
     ),
);

1;

