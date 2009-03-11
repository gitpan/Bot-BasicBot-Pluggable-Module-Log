#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 15;

BEGIN {
	*CORE::GLOBAL::localtime = sub  { return (37,21,9,11,2,109,3,69,0) };
}

package Bot::BasicBot::Pluggable::Module::TestLog;

use base qw(Bot::BasicBot::Pluggable::Module::Log);

my $last_log;

sub _log_to_file { $last_log = $_[2]; }
sub last_log    { return $last_log;  }
sub clear_log    { $last_log = '';    }

package main;


use Bot::BasicBot::Pluggable;

my $store = Bot::BasicBot::Pluggable::Store->new();

my $bot = Bot::BasicBot::Pluggable->new(
  channels => [ '#botzone' ],
  nick     => 'TestBot',
  store    => $store
);

my $module = Bot::BasicBot::Pluggable::Module::TestLog->new(Bot => $bot);


my $message              = { channel => '#botzone', body => 'Foobar!', who => 'bob' };
my $message_from_bot     = { channel => '#botzone', body => 'Foobar!', who => 'TestBot' };
my $message_to_bot       = { channel => '#botzone', body => 'Foobar!', who => 'bob',  address => 'TestBot' };
my $foobarless_message   = { channel => '#botzone', body => 'Bar!', who => 'bob',  address => 'TestBot' };

is($module->_filename($message),'./botzone_20090311.log','filname in current directory');

$module->set('user_log_path','/tmp');

is($module->_filename($message),'/tmp/botzone_20090311.log','filname in after set directory to /tmp/');

is($module->_format_message($message,'Foobar!'),'[#botzone 09:21:37] Foobar!','format_message');

$module->seen($message);
is($module->last_log(),'[#botzone 09:21:37] <bob> Foobar!','Log message');

$module->chanjoin($message);
is($module->last_log(),'[#botzone 09:21:37] JOIN: bob','Log message');

$module->chanpart($message);
is($module->last_log(),'[#botzone 09:21:37] PART: bob','Log message');

$module->clear_log;
$module->set('user_ignore_joinpart',1);

$module->chanjoin($message);
is($module->last_log(),'','Log message');

$module->chanpart($message);
is($module->last_log(),'','Log message');

$module->clear_log;

$module->seen($message_from_bot);
is($module->last_log(),'','Log message');

$module->seen($message_to_bot);
is($module->last_log(),'','Log message');

$module->clear_log;
$module->set('user_ignore_bot',0);

$module->seen($message_from_bot);
is($module->last_log(),'[#botzone 09:21:37] <TestBot> Foobar!','Log message');

$module->seen($message_to_bot);
is($module->last_log(),'[#botzone 09:21:37] <bob> Foobar!','Log message');

is($module->help(),'Logs all activities in a channel.','expected help message');

$module->clear_log;
$module->set('user_ignore_pattern', 'Foobar');
$module->seen($message);
is($module->last_log(),'','Log message');

$module->seen($foobarless_message);
is($module->last_log(),'[#botzone 09:21:37] <bob> Bar!','Log message');


1;
