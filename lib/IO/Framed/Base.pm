package IO::Framed::Base;

use strict;
use warnings;

sub get_filehandle {
    return $_[0]->{'_fh'};
}

1;
