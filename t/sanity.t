use Test::More;

plan tests => 5;

use_ok 'IO::Framed::Read';
use_ok 'IO::Framed::ReadWrite::Blocking';
use_ok 'IO::Framed::ReadWrite::NonBlocking';
use_ok 'IO::Framed::Write::Blocking';
use_ok 'IO::Framed::Write::NonBlocking';
