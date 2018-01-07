#!/usr/bin/env perl

use strict;
use warnings;

BEGIN { eval 'use autodie;' }

use Test::More;
plan tests => 6;

use File::Temp ();
use IO::Handle ();

use IO::Framed ();

(undef, my $path) = File::Temp::tempfile( CLEANUP => 1 );

open my $fh, '+<', $path;
$fh->blocking(0);

my $iof = IO::Framed->new($fh);

$iof->write('Hello');

sysseek $fh, 0, 0;

my $two = $iof->read(2);
is( $two, 'He', 'initial read (so write defaults to no write queue)' );

my $failed = $iof->read(5);
is( $failed, undef, 'can’t read full payload? return undef' );

$iof->enable_write_queue();
$iof->write('!!');

is( $failed, undef, 'after write queue enabled, write() doesn’t write' );

is( $iof->get_write_queue_count(), 1, 'get_write_queue_count()' );

$iof->flush_write_queue();

sysseek $fh, 5, 0;

my $done = $iof->read(5);
is( $done, 'llo!!', 'finished with rest of read' );

#----------------------------------------------------------------------

my $stdin_iof = IO::Framed->new(\*STDIN, 'ohh');
diag explain $stdin_iof;

is( $stdin_iof->read(3), 'ohh', 'seed text' );
