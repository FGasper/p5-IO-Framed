use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use Socket;
use IO::File ();    #so blocking() will work

BEGIN {
    unshift @INC, '../lib';
}

use IO::Framed::Read ();

my ($r, $w);
if ($^O eq 'MSWin32'){
    require Win32::Socketpair;
    ($r, $w) = Win32::Socketpair::winsocketpair();
} else {
    pipe $r, $w;
}

syswrite $w, 'x' x 3;

my $rdr = IO::Framed::Read->new( $r );

is(
    $rdr->read_until("y"),
    undef,
    '“until” character isn’t there',
);

syswrite $w, 'xxxxyxy';

is(
    $rdr->read_until("y"),
    'xxxxxxxy',
    'got expected input',
);

is(
    $rdr->read_until("y"),
    'xy',
    'got expected input (probably from buffer)',
);

close $w;

throws_ok(
    sub { $rdr->read_until("y") },
    'IO::Framed::X::EmptyRead',
    'exception on empty read',
);

$rdr->allow_empty_read();

is(
    $rdr->read_until("y"),
    q<>,
    'allow_empty_read() - empty string on empty read',
);

done_testing();
