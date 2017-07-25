use strict;
use warnings;

BEGIN {
    eval { use autodie };
}

use Test::More;

plan tests => 4;

use IO::Framed::ReadWrite::Blocking ();
use IO::Framed::ReadWrite::NonBlocking ();

pipe( my $r, my $w );

my $blk = IO::Framed::ReadWrite::Blocking->new( $r, $w );
my $nblk = IO::Framed::ReadWrite::NonBlocking->new( $r, $w );

$blk->write(123);

is( $blk->read(3), 123, 'blocking I/O read and write' );

#----------------------------------------------------------------------

is( $nblk->get_write_queue_count(), 0, 'write queue' );

$nblk->write(456);
is( $nblk->get_write_queue_count(), 1, 'write queue, populated' );

1 while !$nblk->flush_write_queue();

my $in;
($in = $blk->read(3)) while !$in;
is( $in, 456, 'read from non-blocking' );
