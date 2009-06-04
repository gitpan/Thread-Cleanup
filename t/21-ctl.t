#!perl -T

use strict;
use warnings;

use Config qw/%Config/;

BEGIN {
 if (!$Config{useithreads}) {
  require Test::More;
  Test::More->import;
  plan(skip_all => 'This perl wasn\'t built to support threads');
 }
}

use threads;
use threads::shared;

use Test::More tests => 5 + 1;

BEGIN {
 defined and diag "Using threads $_"         for $threads::VERSION;
 defined and diag "Using threads::shared $_" for $threads::shared::VERSION;
}

use Thread::Cleanup;

my @stack : shared;

sub msg { lock @stack; push @stack, join ':', @_ }

Thread::Cleanup::register {
 msg 'cleanup';
 die 'cleanup';
 msg 'not reached 1';
};

{
 local $SIG{__DIE__} = sub { msg 'sig', @_ };
 no warnings 'threads';
 threads->create(sub {
  msg 'spawn';
  die 'thread';
  msg 'not reached 2';
 })->join;
}

msg 'done';

{
 lock @stack;
 is   shift(@stack), 'spawn';
 like shift(@stack), qr/sig:thread at \Q$0\E line \d+/;
 is   shift(@stack), 'cleanup';
 like shift(@stack), qr/sig:cleanup at \Q$0\E line \d+/;
 is   shift(@stack), 'done';
 is_deeply \@stack,  [ ], 'nothing more';
}
