package IO::Framed;

use strict;
use warnings;

our $VERSION = 0.012;

=encoding utf-8

=head1 NAME

IO::Framed - Convenience wrapper for frame-based I/O

=head1 SYNOPSIS

Reading:

    #See below about seed bytes.
    my $reader = IO::Framed::Read->new( $in_fh, 'seed bytes' );

    #This returns undef if the $in_fh doesn’t have at least
    #the given length (5 in this case) of bytes to read.
    $frame = $reader->read(5);

Writing, blocking I/O:

    my $writer = IO::Framed::Write::Blocking->new( $out_fh );

    #The second parameter (if given) is executed immediately after the final
    #byte of the payload is written. For blocking I/O this happens
    #before the following method returns.
    $writer->write('hoohoo', sub { print 'sent!' } );

Writing, non-blocking I/O:

    my $nb_writer = IO::Framed::Write::NonBlocking->new( $out_fh );

    #This just adds to a memory queue:
    $writer->write('hoohoo', sub { print 'sent!' } );

    #This will be 1, since we have 1 message/frame queued to send.
    $writer->get_write_queue_count();

    #Returns 1 if it empties out the queue; 0 otherwise.
    #Partial frame writes are accommodated; the callback given as 2nd
    #argument to write() only fires when the queue item is sent completely.
    my $empty = $writer->flush_write_queue();

There are also C<IO::Framed::ReadWrite::Blocking> and
C<IO::Framed::ReadWrite::NonBlocking>, which combine the features of the
respective read and write modules above.

=head1 DESCRIPTION

While writing L<Net::WAMP> I noticed that I was reimplementing some of the
same patterns I’d used in L<Net::WebSocket> to parse frames from a stream:

=over

=item * Only read() entire frames, with a read queue for any partials.

=item * Continuance when a partial frame is delivered.

=item * Write queue with callbacks for non-blocking I/O

=item * Signal resilience: resume read/write after Perl receives a trapped
signal rather than throwing/giving EINTR. (cf. L<IO::SigGuard>)

=back

These are now made available in this distribution.

=head1 ABOUT READS

The premise here is that you expect a given number of bytes at a given time
and that a partial read should be continued once it is sensible to do so.

As a result, C<read()> will throw an exception if the number of bytes given
for a continuance is not the same number as were originally requested.

Example:

    #This reads only 2 bytes, so read() will return undef.
    $framed->read(10);

    #… wait for readiness if non-blocking …

    #XXX This die()s because we’re in the middle of trying to read
    #10 bytes, not 4.
    $framed->read(4);

    #If this completes the read (i.e., takes in 8 bytes), then it’ll
    #return the full 10 bytes; otherwise, it’ll return undef again.
    $framed->read(10);

EINTR prompts a redo of the read operation. EAGAIN prompts an undef return.
Any other failures prompt an instance of L<IO::Framed::X::ReadError> to be
thrown.

=head1 ABOUT WRITES

Blocking writes are straightforward: the system will always send the entire
buffer.

Non-blocking writes are trickier. Since we can’t know that the output
filehandle is ready right when we want it, we have to queue up our writes
then write them once we know (e.g., through C<select()>) that the filehandle
is ready. Each C<write()> call, then, enqueues one new buffer to write.

Since it’s often useful to know when a payload has been sent,
C<write()> accepts a callback that will be executed immediately
after the last byte of the payload is written to the output filehandle.

Note that both blocking and non-blocking I/O expose a C<write()> method,
though NonBlocking.pm’s module is just a “push” onto a queue. This allows
anything that writes to the object not to care whether it’s blocking or
non-blocking I/O.

Empty out the write queue by calling C<flush_write_queue()> and looking for
a truthy response. (A falsey response means there is still data left in the
queue.) C<get_write_queue_count()> gives you the number of queue items left
to write. (A partially-written item is treated the same as a fully-unwritten
one.)

=head1 EXCEPTIONS THROWN

All exceptions subclass L<X::Tiny::Base>.

=head2 L<IO::Frame::X::ReadError>

=head2 L<IO::Frame::X::WriteError>

These both have an C<OS_ERROR> property (cf. L<X::Tiny::Base>’s accessor
method).

=head2 L<IO::Frame::X::EmptyRead>

No properties. If this is thrown, your peer has probably closed the connection.
You probably should thus always trap this exception.

#----------------------------------------------------------------------

=head1 REPOSITORY

L<https://github.com/FGasper/p5-IO-Framed>

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 COPYRIGHT

Copyright 2017 by L<Gasper Software Consulting, LLC|http://gaspersoftware.com>

=head1 LICENSE

This distribution is released under the same license as Perl.

=cut

1;
