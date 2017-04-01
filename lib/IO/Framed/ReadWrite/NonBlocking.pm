package IO::Framed::ReadWrite::NonBlocking;

use strict;
use warnings;

use parent qw(
    IO::Framed::ReadWrite
    IO::Framed::Write::NonBlocking
);

#copied … TODO deduplicate
sub new {
    my $self = $_[0]->SUPER::new( @_[ 1 .. $#_ ] );

    $self->{'_write_queue'} = [];

    return $self;
}

1;
