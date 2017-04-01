package IO::Framed::Write::Blocking;

use strict;
use warnings;

use parent qw( IO::Framed::Write );

use IO::SigGuard ();

use IO::Framed::X ();

sub write {
    local $!;

    IO::SigGuard::syswrite( $_[0]->{'_out_fh'}, $_[1] ) or do {
        die IO::Framed::X->create('WriteError', $!);
    };

    return;
}

1;
