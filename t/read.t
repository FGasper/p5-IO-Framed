use strict;
use warnings;

use Test::More;

plan tests => 7;

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

is( $rdr->read(2), undef, 'undef when OS gives EAGAIN' );

close $w;

eval { $rdr->read(2) };
isa_ok( $@, 'IO::Framed::X::EmptyRead', 'error from read() on empty' );

close $r;

eval { $rdr->read(2) };

is( $@->errno_is('EBADF'), 1, '… is EAGAIN' ) or diag explain [ $@->get('OS_ERROR'), 0 + $@->get('OS_ERROR') ];

is( $@->errno_is('EPERM'), 0, '… isn’t EPERM' );
