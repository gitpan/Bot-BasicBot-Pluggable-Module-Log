package Bot::BasicBot::Pluggable::Module::Log;

use warnings;
use strict;
use autodie;

use base qw(Bot::BasicBot::Pluggable::Module);

use POSIX qw(strftime);
use File::Spec::Functions qw(catfile curdir);

our $VERSION = '0.02';

sub init {
    my ($self) = @_;
    $self->set( 'user_ignore_pattern', undef )
      if ! defined $self->get('user_ignore_pattern');
    $self->set( 'user_log_path', curdir() )
      if ! defined $self->get('user_log_path');
    $self->set( 'user_timestamp_fmt', '%H:%M:%S' )
      if ! defined $self->get('user_timestamp_fmt');
    $self->set( 'user_ignore_bot', 1 )
      if ! defined $self->get('user_ignore_bot');
    $self->set( 'user_ignore_joinpart', 0 )
      if ! defined $self->get('user_ignore_joinpart');
    return;
}

sub seen {
    my ( $self, $message ) = @_;

    my $body = $message->{body};
    my $who  = '<' . $message->{who} . '> ';
    my $nick = $self->bot->nick();

    if ( $self->get('user_ignore_bot') ) {
        return if $message->{who} eq $nick;
        return if $message->{address} and $message->{address} eq $nick;
    }

    if ( $self->get('user_ignore_pattern') ) {
        my $pattern = $self->get('user_ignore_pattern');
        return if $body =~ /$pattern/;
    }

    $self->_log( $message, $who . $body );
    return;
}

sub chanjoin {
    my ( $self, $message ) = @_;
    return if $self->get('user_ignore_joinpart');
    $self->_log( $message, 'JOIN: ' . $message->{who} );
    return;
}

sub chanpart {
    my ( $self, $message ) = @_;
    return if $self->get('user_ignore_joinpart');
    $self->_log( $message, 'PART: ' . $message->{who} );
    return;
}

sub help {
    return 'Logs all activities in a channel.';
}

sub _log {
    my ( $self, $message, $text ) = @_;
    my $logstr = $self->_format_message( $message, $text );
    $self->_log_to_file( $message, $logstr );
    return 1;
}

sub _log_to_file {
    my ( $self, $message, $logstr ) = @_;

    my $file = $self->_filename($message);

    open( my $log, '>>', catfile($file) );
    print {$log} $logstr . "\n";
    close($log);
    return;
}

sub _filename {
    my ( $self, $message ) = @_;

    my $channel = $message->{channel};
    $channel =~ s/^#//;
    my $file = $channel . '_' . strftime( '%Y%m%d', localtime ) . '.log';
    my $path = $self->get('user_log_path');

    return catfile( $path, $file );
}

sub _format_message {
    my ( $self, $message, $text ) = @_;

    my $timestamp = strftime( $self->get('user_timestamp_fmt'), localtime );
    my $log_str = '[' . $message->{channel} . " $timestamp] $text";

    return $log_str;
}

=pod

=head1 NAME

Bot::BasicBot::Pluggable::Module::Log - Provide logging for Bot::BasicBot::Pluggable

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

This module logs all traffic in irc channels to files. Every channel is
logged to its own logfile and all files are rotated every 24 hours. For
the sake of simplicity this module implements a very straightforward
logging mechanism. Please take a look at the BUGS section for its
limitations.

=head1 IRC USAGE

None. If the module is loaded every message, join and part event is
recorded in the channel's log file.

=head1 FUNCTIONS

=head2 seen

The bot calls this functions for every message sent to the channel. The
message is then formatted and sent further to the loggings subsystem. If
the message is from the bot or addressed to it and C<ignore_bot> is set
to a true value, those messages are not logged. The same applies if the
body of the message matches the pattern defined in C<ignore_pattern>. The
default logging output would look something like

[#botzone 12:34:12] <me> Hello World

=head2 chanjoin

This function is called every time someone enters the channel. The event
is logged as follows:

[#botzone 12:34:12] JOIN: me

=head2 chanpart

This function is called every time someone leaves the channel. The event
is logged as follows:

[#botzone 12:34:12] PART: me

=head2 help

Print a friendly help message to the channel.

=head2 init

Sets all user variables to their default values. Please see the next
section for further information about their exact values.

=head1 VARIABLES

=head2 ignore_pattern

All lines mattching this regular expression will b<not> be logged at
all. Normally all lines are logged.

=head2 log_path

Path to the directory where all logfiles are stored. Defaults to the
current directory.

=head2 timestamp_fmt

Format of the timestamp that is prepended to every logged
statement. Defaults to '%H:%M:%S'. Consult your system's strftime()
manpage for details about these and the other arguments.

=head2 ignore_bot

Whether to ignore all communications with this bot. Defaults to 1.
	
=head2 ignore_joinpart

Whether to log join and part events. Defaults to 0.

=head1 AUTHOR

Mario Domgoergen, C<< <dom at math.uni-bonn.de> >>

=head1 BUGS

=over 4

=item 

For the sake of simplicity this module opens and closes the logfile
every time a message is written. This is far from optimal, but save me
the hassle to save open filehandles between invocations, locking over
nfs and rotating the log files. In the future there will be a submodule to
use Log::Log4perl or Log::Dispatch.

=item

No file is locked, so there could be a possible problem with multiple
bots writing to the same file. This will also be solved by using one of
the serious logging modules mentioned above.

=back

Please report any bugs or feature requests
to C<bug-bot-basicbot-pluggable-module-log
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-Log>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::Log


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-Log>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-Log>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-Log>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-Log>

=back


=head1 SEE ALSO

=over 4

=item 

L<Bot::BasicBot::Pluggable>

=item 

L<Bot::BasicBot>

=back 

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Bot::BasicBot::Pluggable::Module::Log
