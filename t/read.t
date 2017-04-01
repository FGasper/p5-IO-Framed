use strict;
use warnings;

use Test::More;

plan tests => 6;

use Socket;

use IO::Framed::Read ();

pipe my $r, my $w;

syswrite $w, 'x' x 3;

my $rdr = IO::Framed::Read->new( $r );

my $f = $rdr->read(2);
is( $f, 'xx', '2-byte frame OK' );

$f = $rdr->read(2);
is( $f, undef, 'undef when full frame not available' );

syswrite $w, 'y';
$f = $rdr->read(2);
is( $f, 'xy', '2-byte frame now OK' );

$r->blocking(0);

eval {
    $rdr->read(2);
};
isa_ok( $@, 'IO::Framed::X::ReadError', 'error from read() on empty' );
is( $@->errno_is('EAGAIN'), 1, '… is EAGAIN' );

is( $@->errno_is('EPERM'), 0, '… isn’t EPERM' );
