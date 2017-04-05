package IO::Framed::Write::NonBlocking;

use strict;
use warnings;

use parent qw( IO::Framed::Write );

use IO::SigGuard ();

use IO::Framed::X ();

sub new {
    my $self = $_[0]->SUPER::new( @_[ 1 .. $#_ ] );

    $self->{'_write_queue'} = [];

    return $self;
}

sub write {
    my $self = shift;

    push @{ $self->{'_write_queue'} }, \@_;

    return;
}

#----------------------------------------------------------------------

our $_allow_EAGAIN;

sub flush_write_queue {
    my ($self) = @_;

    local $_allow_EAGAIN;

    while ( my $qi = $self->{'_write_queue'}[0] ) {
        return 0 if !$self->_write_now_then_callback( @$qi );

        shift @{ $self->{'_write_queue'} };
        $_allow_EAGAIN = 1;
    }

    return 1;
}

sub get_write_queue_count {
    my ($self) = @_;

    return 0 + @{ $self->{'_write_queue'} };
}

#----------------------------------------------------------------------

sub _write_now_then_callback {
    local $!;

    my $wrote = IO::SigGuard::syswrite( $_[0]->{'_out_fh'}, $_[1] ) || do {

        if ($! && !$!{'EAGAIN'} && !$!{'EWOULDBLOCK'}) {
            die IO::Framed::X->create('WriteError', $!);
        }

        return undef;
    };

    if ($wrote == length $_[1]) {
        $_[0]->{'_write_queue_partial'} = 0;
        $_[2]->() if $_[2];
        return 1;
    }

    #Trim the bytes that we did send.
    substr( $_[1], 0, $wrote ) = q<>;

    #This seems useful to track … ??
    $_[0]->{'_write_queue_partial'} = 1;

    return 0;
}

1;
