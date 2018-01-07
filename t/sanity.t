use Test::More;

plan tests => 8;

use_ok 'IO::Framed';
use_ok 'IO::Framed::Read';
use_ok 'IO::Framed::Write';

use_ok 'IO::Framed::ReadWrite';
use_ok 'IO::Framed::ReadWrite::Blocking';
use_ok 'IO::Framed::ReadWrite::NonBlocking';
use_ok 'IO::Framed::Write::Blocking';
use_ok 'IO::Framed::Write::NonBlocking';
