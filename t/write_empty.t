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

    throws_ok(
        sub { $io->write(q<>) },
        'IO::Framed::X::EmptyWrite',
        "$label: die() on empty-string write()",
    );

    throws_ok(
        sub { $io->write(undef) },
        'IO::Framed::X::EmptyWrite',
        "$label: die() on undefined write()",
    );

    throws_ok(
        sub { $io->write() },
        'IO::Framed::X::EmptyWrite',
        "$label: die() on empty write()",
    );

    #----------------------------------------------------------------------

    my $cb_called = 0;
    my $cb = sub { $cb_called++ };

    throws_ok(
        sub { $io->write(q<>, $cb) },
        'IO::Framed::X::EmptyWrite',
        "$label: die() on empty-string write() with callback",
    );

    ok( !$cb_called, '… and the callback wasn’t called' );

    throws_ok(
        sub { $io->write(undef, $cb) },
        'IO::Framed::X::EmptyWrite',
        "$label: die() on undefined write() with callback",
    );

    ok( !$cb_called, '… and the callback wasn’t called' );
}
