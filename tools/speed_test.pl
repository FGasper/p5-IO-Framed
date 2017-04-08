#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark;

#use IO::Framed::Read ();

#----------------------------------------------------------------------

package NoIoctlRead;

use parent qw( IO::Framed::Read );

use constant FIONREAD => undef;

#----------------------------------------------------------------------

use Socket;

socketpair my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC;
socketpair my $c, my $d, AF_UNIX, SOCK_STREAM, PF_UNSPEC;

Benchmark::cmpthese( 100, {
    w_ioctl => sub {
        my $iof = IO::Framed::Read->new( $a );
        for ( 1 .. 10000 ) {
            syswrite $b, 'x';
            $iof->read(100);
        }
    },
    no_ioctl => sub {
        my $iof = NoIoctlRead->new( $a );
        for ( 1 .. 10000 ) {
            syswrite $b, 'x';
            $iof->read(100);
        }
    },
} );
