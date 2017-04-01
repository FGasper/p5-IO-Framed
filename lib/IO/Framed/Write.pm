package IO::Framed::Write;

use strict;
use warnings;

sub new {
    my ( $class, $out_fh ) = @_;

    if ( !$class->can('write') ) {
        die "$class has no write() method! Try ::NonBlocking or ::Blocking?";
    }

    my $self = {
        _out_fh => $out_fh,
    };

    return bless $self, $class;
}

sub get_output_fh { return $_[0]->{'_out_fh'} }

1;
