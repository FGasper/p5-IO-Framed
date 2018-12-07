# NAME

IO::Framed - Convenience wrapper for frame-based I/O

# SYNOPSIS

Reading:

    #See below about seed bytes.
    my $iof = IO::Framed->new( $fh, 'seed bytes' );

    #This returns undef if the $in_fh doesn’t have at least
    #the given length (5 in this case) of bytes to read.
    $frame = $iof->read(5);

    #Don’t call this after an incomplete read().
    $line_or_undef = $iof->read_until("\x0a");

Writing, unqueued (i.e., for blocking writes):

    #The second parameter (if given) is executed immediately after the final
    #byte of the payload is written. For blocking I/O this happens
    #before the following method returns.
    $iof->write('hoohoo', sub { print 'sent!' } );

Writing, queued (for non-blocking writes):

    $iof->enable_write_queue();

    #This just adds to a memory queue:
    $iof->write('hoohoo', sub { print 'sent!' } );

    #This will be 1, since we have 1 message/frame queued to send.
    $iof->get_write_queue_count();

    #Returns 1 if it empties out the queue; 0 otherwise.
    #Partial frame writes are accommodated; the callback given as 2nd
    #argument to write() only fires when the queue item is sent completely.
    my $empty = $iof->flush_write_queue();

You can also use `IO::Framed::Read` and `IO::Framed::Write`, which
contain just the read and write features. (`IO::Framed` is actually a
subclass of them both.)

# DESCRIPTION

While writing [Net::WAMP](https://metacpan.org/pod/Net::WAMP) I noticed that I was reimplementing some of the
same patterns I’d used in [Net::WebSocket](https://metacpan.org/pod/Net::WebSocket) to parse frames from a stream:

- Only read() entire frames, with a read queue for any partials.
- Continuance when a partial frame is delivered.
- Write queue with callbacks for non-blocking I/O
- Signal resilience: resume read/write after Perl receives a trapped
signal rather than throwing/giving EINTR. (cf. [IO::SigGuard](https://metacpan.org/pod/IO::SigGuard))

These are now made available in this distribution.

# ABOUT READS

The premise here is that you expect a given number of bytes at a given time
and that a partial read should be continued once it is sensible to do so.

As a result, `read()` will throw an exception if the number of bytes given
for a continuance is not the same number as were originally requested.
`read_until()` will throw a similar exception if called between an incomplete
`read()` and its completion.

Example:

    #This reads only 2 bytes, so read() will return undef.
    $iof->read(10);

    #… wait for readiness if non-blocking …

    #XXX This die()s because we’re in the middle of trying to read
    #10 bytes, not 4.
    $iof->read(4);

    #If this completes the read (i.e., takes in 8 bytes), then it’ll
    #return the full 10 bytes; otherwise, it’ll return undef again.
    $iof->read(10);

EINTR prompts a redo of the read operation. EAGAIN and EWOULDBLOCK (the same
error generally, but not always) prompt an undef return.
Any other failures prompt an instance of [IO::Framed::X::ReadError](https://metacpan.org/pod/IO::Framed::X::ReadError) to be
thrown.

## End-Match Reads

Reader modules now implement a `read_until()` method, which reads arbitrarily
many bytes until
a given sequence of bytes appears then returns those bytes (plus the looked-for
sequence in the return). An obvious application for this feature
is line-by-line reads, e.g., to implement HTTP or other line-based protocols.

## Empty Reads

This class’s `read()` and `read_until()` methods will, by default, throw
an instance of
[IO::Framed::X::EmptyRead](https://metacpan.org/pod/IO::Framed::X::EmptyRead) on an empty read. This is normal and logical
behavior in contexts (like [Net::WebSocket](https://metacpan.org/pod/Net::WebSocket)) where the data stream itself
indicates when no more data will come across. In such cases an empty read
is genuinely an error condition: it either means you’re reading past when
you should, or the other side prematurely went away.

In some other cases, though, that empty read is the normal and expected way
to know that a filehandle/socket has no more data to read.

If you prefer, then, you can call the `allow_empty_read()` method to switch
to a different behavior, e.g.:

    $framed->allow_empty_read();

    my $frame = $framed->read(10);

    if (length $frame) {
        #yay, we got a frame!
    }
    elsif (defined $frame) {
        #no more data will come in, so let’s close up shop
    }
    else {
        #undef means we just haven’t gotten as much data as we want yet;
        #in this case, that means fewer than 10 bytes are available.
    }

    #----------------------------------------------------------------------
    # The same example as above with line-oriented input …

    my $line = $framed->read_until("\x0a");

    if (length $line) {
        #yay, we got a line!
    }
    elsif (defined $line) {
        #no more data will come in, so let’s close up shop
    }
    else {
        #undef means we just haven’t gotten a full line yet.
    }

Instead of throwing the aforementioned exception, `read()` now returns
empty-string on an empty read. That means that you now have to distinguish
between multiple “falsey” states: undef for when the requested number
of bytes hasn’t yet arrived, and empty string for when no more bytes
will ever arrive. But it is also true now that the only exceptions thrown
are bona fide **errors**, which will suit some applications better than the
default behavior.

NB: If you want to be super-light, you can bring in IO::Framed::Read instead
of the full IO::Framed. (IO::Framed is already pretty lightweight, though.)

# ABOUT WRITES

Writes for blocking I/O are straightforward: the system will always send
the entire buffer. The OS’s `write()` won’t return until everything
meant to be written is written. Life is pleasant; life is simple. :)

Non-blocking I/O is trickier. Not only can the OS’s `write()` write
a subset of the data it’s given, but we also can’t know that the output
filehandle is ready right when we want it. This means that we have to queue up
our writes
then write them once we know (e.g., through `select()`) that the filehandle
is ready. Each `write()` call, then, enqueues one new buffer to write.

Since it’s often useful to know when a payload has been sent,
`write()` accepts an optional callback that will be executed immediately
after the last byte of the payload is written to the output filehandle.

Empty out the write queue by calling `flush_write_queue()` and looking for
a truthy response. (A falsey response means there is still data left in the
queue.) `get_write_queue_count()` gives you the number of queue items left
to write. (A partially-written item is treated the same as a fully-unwritten
one.)

Note that, while it’s acceptable to activate and deactive the write queue,
the write queue must be empty in order to deactivate it. (You’ll get a
nasty, untyped exception otherwise!)

`write()` returns undef on EAGAIN and EWOULDBLOCK. It retries on EINTR,
so you should never actually see this error from this module.
Other errors prompt a thrown exception.

NB: `enable_write_queue()` and `disable_write_queue()` return the object,
so you can instantiate thus:

    my $nb_writer = IO::Framed::Write->new($fh)->enable_write_queue();

NB: If you want to be super-light, you can bring in IO::Framed::Write instead
of the full IO::Framed. (IO::Framed is already pretty lightweight, though.)

# CUSTOM READ & WRITE LOGIC

As of version 0.04, you can override READ and WRITE methods with your
preferred logic. For example, in Linux you might prefer `send()` rather than
`syswrite()` to avoid SIGPIPE, thus:

    package My::Framed;

    use parent qw( IO::Framed::Write );

    #Only these two arguments are given.
    sub WRITE {
        return send( $_[0], $_[1], Socket::MSG_NOSIGNAL );
    }

(NB: In \*BSD OSes you can set SO\_SIGNOPIPE on the filehandle instead.)

You can likewise set `READ()` to achieve the same effect for reads.
(`READ()` receives all four arguments that `sysread()` can consume.)

**IMPORTANT:** Unlike most inherited methods, `READ()` and `WRITE()` do
NOT receive the object instance. They must follow the same semantics as
Perl’s `sysread()` and `syswrite()`: i.e., they must return the number
of bytes read/written, or return undef and set `$!` appropriately on error.

# ERROR RESPONSES

An empty read or any I/O error besides the ones mentioned previously
are indicated via an instance of one of the following exceptions.

All exceptions subclass [IO::Framed::X::Base](https://metacpan.org/pod/IO::Framed::X::Base), which itself
subclasses `X::Tiny::Base`.

- [IO::Framed::X::ReadError](https://metacpan.org/pod/IO::Framed::X::ReadError)
- [IO::Framed::X::WriteError](https://metacpan.org/pod/IO::Framed::X::WriteError)

    These both have an `OS_ERROR` property (cf. [X::Tiny::Base](https://metacpan.org/pod/X::Tiny::Base)’s accessor
    method).

- [IO::Framed::X::EmptyRead](https://metacpan.org/pod/IO::Framed::X::EmptyRead)

    No properties. If this is thrown, your peer has probably closed the connection.
    Unless you have called `allow_empty_read()` to set an alternate behavior,
    you might want to trap this exception if you call `read()`.

**NOTE:** This distribution doesn’t write to `$!`. EAGAIN and EWOULDBLOCK on
`flush_write_queue()` are ignored; all other errors are converted
to thrown exceptions.

# LEGACY CLASSES

This distribution also includes the following **DEPRECATED** legacy classes:

- IO::Framed::Write::Blocking
- IO::Framed::Write::NonBlocking
- IO::Framed::ReadWrite
- IO::Framed::ReadWrite::Blocking
- IO::Framed::ReadWrite::NonBlocking

I’ll keep these in for the time being but eventually **WILL** remove them.
Please adjust any calling code that you might have.

# REPOSITORY

[https://github.com/FGasper/p5-IO-Framed](https://github.com/FGasper/p5-IO-Framed)

# AUTHOR

Felipe Gasper (FELIPE)

# COPYRIGHT

Copyright 2017 by [Gasper Software Consulting, LLC](http://gaspersoftware.com)

# LICENSE

This distribution is released under the same license as Perl.
