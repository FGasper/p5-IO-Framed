use strict;
use warnings;
use autodie;

use Test::More;

plan tests => 8;

use Socket;
use IO::File ();    #so blocking() will work

use IO::Framed::Write ();

my ($r, $w);
if ($^O eq 'MSWin32'){
    require Win32::Socketpair;
    ($r, $w) = Win32::Socketpair::winsocketpair();
} else {
    pipe $r, $w;
}

my $w_rin = q<>;
vec( $w_rin, fileno($w), 1 ) = 1;

$w->blocking(0);

sub _fill_pipe {
    local $@;
    eval { syswrite $w, 'x' while 1 };
}

#----------------------------------------------------------------------
#_fill_pipe();

my $bw = IO::Framed::Write->new( $w );

is( $bw->get_filehandle(), $w, 'get_filehandle()' );

is(
    $bw->flush_write_queue(),
    1,
    'no-op flush_write_queue() on blocking',
);

is(
    $bw->get_write_queue_count(),
    0,
    'no-op get_write_queue_size() on blocking',
);

my $nbw = IO::Framed::Write->new( $w )->enable_write_queue();

eval { $bw->write('y') while 1 };

isa_ok(
    $@,
    'IO::Framed::X::WriteError',
    'error from flushing to a full buffer',
) or diag explain $@;

my $wrote_1;
my $wrote_2;

$nbw->write('123', sub { $wrote_1 = 1 } );
$nbw->write('123', sub { $wrote_2 = 1 } );

my $buf;

sysread $r, $buf, 1;

is(
    $nbw->flush_write_queue(),
    0,
    'flush_write_queue() - false return on incomplete write',
);

is(
    $nbw->get_write_queue_count(),
    $wrote_1 ? 1 : 2,
    'get_write_queue_count() - when the queue is actually not empty',
);

my $flushed;
while (!$wrote_2) {
    sysread $r, $buf, 1 ;
    $flushed = $nbw->flush_write_queue();
}

is(
    $flushed,
    1,
    'flush_write_queue() - true once we empty the write queue',
);

is(
    $nbw->get_write_queue_count(),
    0,
    'get_write_queue_count() - now empty',
);
