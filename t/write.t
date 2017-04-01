use strict;
use warnings;
use autodie;

use Test::More;

plan tests => 4;

use Socket;

use IO::Framed::Write::Blocking ();
use IO::Framed::Write::NonBlocking ();

pipe my $r, my $w;
diag explain "w:" . fileno $w;

my $w_rin = q<>;
vec( $w_rin, fileno($w), 1 ) = 1;

$w->blocking(0);

sub _fill_pipe {
    local $@;
    eval { syswrite $w, 'x' while 1 };
}

#----------------------------------------------------------------------
#_fill_pipe();

my $bw = IO::Framed::Write::Blocking->new( $w );
my $nbw = IO::Framed::Write::NonBlocking->new( $w );

eval { $bw->write('y') while 1 };

isa_ok(
    $@,
    'IO::Framed::X::WriteError',
    'error from flushing to a full buffer',
) or diag explain $@;

$nbw->write('123');
$nbw->write('123');

my $buf;

sysread $r, $buf, 1;

is(
    $nbw->flush_write_queue(),
    0,
    'flush_write_queue() - false return on incomplete write',
);

sysread $r, $buf, 3;

is(
    $nbw->flush_write_queue(),
    0,
    'flush_write_queue() - false even when we got a message sent off',
);

sysread $r, $buf, 2;

is(
    $nbw->flush_write_queue(),
    1,
    'flush_write_queue() - true once we empty the write queue',
);
