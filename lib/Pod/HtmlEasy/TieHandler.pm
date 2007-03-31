#############################################################################
## Name:        TieHandler.pm
## Purpose:     Pod::HtmlEasy::TieHandler
## Author:      Graciliano M. P.
## Modified by: Geoffrey Leach
## Created:     2/14/2007
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

# The function of this package is to provide a print function that is
# tied to a filehandle which is then passed as the output file to
# Pod::Parser. Note that only PRINT() and CLOSE() are defined.
# PRINT() accumulates output in an anon array, which is then referenced
# by the defining function.

package Pod::HtmlEasy::TieHandler;

use strict;
use warnings;

our $VERSION = 0.02;

sub TIEHANDLE {
    my $class  = shift;
    my $scalar = shift;

    return bless $scalar, $class;
}

sub PRINT {
    my $this = shift;

    push @{$this}, @_;
    return 1;
}

sub FILENO { return 1; }
sub CLOSE  { return 1; }

#######
# END #
#######

1;

