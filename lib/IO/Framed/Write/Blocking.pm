package IO::Framed::Write::Blocking;

use strict;
use warnings;

use parent qw( IO::Framed::Write );

use IO::SigGuard ();

use IO::Framed::X ();

#Define these so applications can “run the queue” as though
#this were a NonBlocking instance.
use constant {
    flush_write_queue => 1,
    get_write_queue_count => 0,
};

sub write {
    local $!;

    IO::SigGuard::syswrite( $_[0]->{'_out_fh'}, $_[1] ) or do {
        die IO::Framed::X->create('WriteError', $!);
    };

    return;
}

1;
