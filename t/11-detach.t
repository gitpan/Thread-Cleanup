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

use Test::More tests => 5 * (2 + 2) + 1;

use Thread::Cleanup;

my %called : shared;
my %nums   : shared;

our $x = -1;

Thread::Cleanup::register {
 my $tid = threads->tid;
 {
  lock %called;
  $called{$tid}++;
 }

 my $num = do {
  lock %nums;
  $nums{$tid};
 };

 is $x, $num, "\$x in destructor of thread $tid";
 local $x = $tid;
};

my %ran : shared;

sub cb {
 my ($y) = @_;

 my $tid = threads->tid;
 {
  lock %ran;
  $ran{$tid}++;
 }

 {
  lock %nums;
  $nums{$tid} = $y;
 }
 is $x, $y, "\$x in thread $tid";
 local $x = -$tid;

 sleep 1;
}

my @tids;

my @t = map {
 local $x = $_;
 my $thr = threads->create(\&cb, $_);
 push @tids, $thr->tid;
 $thr;
} 0 .. 4;

diag "Using threads $threads::VERSION";
diag "Using threads::shared $threads::shared::VERSION";

$_->detach for @t;

sleep 2;

is $x, -1, '$x in the main thread';

is $ran{$_},    1, "thread $_ was run once" for @tids;

END {
 is $called{$_}, 1, "thread $_ destructor was called once" for @tids;
}
