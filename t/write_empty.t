use strict;
use warnings;
use autodie;

use Test::More;
use Test::NoWarnings;
use Test::Exception;

plan tests => 1 + 14;

use IO::Framed::Write;

my $block = IO::Framed::Write->new(\*STDOUT);
my $nblock = IO::Framed::Write->new(\*STDOUT);

my @t = (
    [ blocking => $block ],
    [ 'non-blocking' => $nblock ],
);

for my $test ( @t ) {
    my ($label, $io) = @$test;

    dies_ok(
        sub { $io->write(q<>) },
        "$label: die() on empty-string write()",
    );

    dies_ok(
        sub { $io->write(undef) },
        "$label: die() on undefined write()",
    );

    dies_ok(
        sub { $io->write() },
        "$label: die() on empty write()",
    );

    #----------------------------------------------------------------------

    my $cb_called = 0;
    my $cb = sub { $cb_called++ };

    dies_ok(
        sub { $io->write(q<>, $cb) },
        "$label: die() on empty-string write() with callback",
    );

    ok( !$cb_called, '… and the callback wasn’t called' );

    dies_ok(
        sub { $io->write(undef, $cb) },
        "$label: die() on undefined write() with callback",
    );

    ok( !$cb_called, '… and the callback wasn’t called' );
}
