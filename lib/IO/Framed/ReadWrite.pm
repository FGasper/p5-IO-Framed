package IO::Framed::ReadWrite;

use strict;
use warnings;



package IO::Framed::Write;

use strict;
use warnings;

use parent qw(
    IO::Framed::Read
    IO::Framed::Write
)

sub new {
    my ( $class, $in_fh, $out_fh, $initial_buffer ) = @_;

    if ( $class eq __PACKAGE__ ) {
        die "$class is a base class! Maybe you want ::NonBlocking or ::Blocking.";
    }

    my $self = IO::Framed::Read->new( $in_fh, $initial_buffer );

    $self->{'_out_fh'} = $out_fh || $in_fh,

    return bless $self, $class;
}

1;
