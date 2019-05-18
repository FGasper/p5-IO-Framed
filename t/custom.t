use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

plan tests => 2;

my $WRITTEN;

{
    package My::Framed;

    use parent qw( IO::Framed );

    sub READ {
        my ($fh) = @_;

        die if !$fh->isa('GLOB');

        $_[1] .= ('x') x $_[2];

        return $_[2];
    }

    sub WRITE {
        my ($fh, $payload) = @_;

        $WRITTEN .= $payload;

        return length $payload;
    }
}

my $framed = My::Framed->new(\*STDIN);

is(
    $framed->read(7),
    'xxxxxxx',
    'READ override',
);

$framed->write('Hello');

is( $WRITTEN, 'Hello', 'WRITE override' );
