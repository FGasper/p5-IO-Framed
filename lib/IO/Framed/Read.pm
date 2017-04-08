package IO::Framed::Read;

use strict;
use warnings;

use IO::SigGuard ();

use IO::Framed::X ();

use constant FIONREAD => ($^O eq 'linux') ? 21531 : ($^O eq 'darwin') ? 1074030207 : undef;

#use constant BUFSIZ => 65536;

sub new {
    my ( $class, $in_fh, $initial_buffer ) = @_;

    if ( !defined $initial_buffer ) {
        $initial_buffer = q<>;
    }

    my $self = {
        _in_fh         => $in_fh,
        _read_buffer   => $initial_buffer,
        _bytes_to_read => 0,
    };

    if ( FIONREAD && -S $in_fh ) {
        require Socket;
        local $!;
        $self->{'_recv_buf'} = unpack 'I', getsockopt( $in_fh, Socket::SOL_SOCKET(), Socket::SO_RCVBUF() );
        die "getsockopt(SOL_SOCKET, SO_RCVBUF): $!" if $!;
    }

    return bless $self, $class;
}

sub get_read_fh { return $_[0]->{'_in_fh'} }

#----------------------------------------------------------------------
# IO subclass interface

my $buf_len;

#We assume here that whatever read may be incomplete at first
#will eventually be repeated so that we can complete it. e.g.:
#
#   - read 4 bytes, receive 1, cache it - return q<>
#   - select()
#   - read 4 bytes again; since we already have 1 byte, only read 3
#       … and now we get the remaining 3, so return the buffer.
#
sub read {
    my ( $self, $bytes ) = @_;

    die "I refuse to read zero!" if !$bytes;

    if ( $buf_len = length $self->{'_read_buffer'} ) {
        if ( $buf_len + $self->{'_bytes_to_read'} != $bytes ) {
            my $should_be = $buf_len + $self->{'_bytes_to_read'};
            die "Continuation: should want “$should_be” bytes, not $bytes!";
        }
    }

    if ( $bytes > $buf_len ) {
        $bytes -= $buf_len;

        local $!;

        if ($self->{'_recv_buf'}) {
            ioctl( $self->{'_in_fh'}, FIONREAD, my $pending = q<> ) or die "ioctl: $!";
            return undef if unpack('I', $pending) < $bytes;
        }

        $bytes -= IO::SigGuard::sysread( $self->{'_in_fh'}, $self->{'_read_buffer'}, $bytes, $buf_len ) || do {
            if ($!) {
                if ( !$!{'EAGAIN'} && !$!{'EWOULDBLOCK'}) {
                    die IO::Framed::X->create( 'ReadError', $! );
                }
            }
            else {
                die IO::Framed::X->create('EmptyRead');
            }
        };
    }

    $self->{'_bytes_to_read'} = $bytes;

    if ($bytes) {
        return undef;
    }

    return substr( $self->{'_read_buffer'}, 0, length($self->{'_read_buffer'}), q<> );
}

#----------------------------------------------------------------------

1;
