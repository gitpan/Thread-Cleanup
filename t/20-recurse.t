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

my ($num, $depth);
BEGIN {
 $num   = 3;
 $depth = 2;
}

use Test::More tests => (($num ** ($depth + 1) - 1) / ($num - 1) - 1 ) * (2 + 2) + 1;

BEGIN {
 defined and diag "Using threads $_"         for $threads::VERSION;
 defined and diag "Using threads::shared $_" for $threads::shared::VERSION;
}

use Thread::Cleanup;

diag 'This will leak some scalars';

our $x = -1;

my %ran    : shared;
my %nums   : shared;
my %called : shared;

my @tids;

sub spawn {
 my ($num, $depth) = @_;
 @tids = ();
 return unless $depth > 0;
 map {
  local $x = $_;
  my $thr = threads->create(\&cb, $_, $depth);
  push @tids, $thr->tid;
  $thr;
 } 1 .. $num;
}

sub check {
 lock %ran;
 lock %called;
 for (@tids) {
  is $ran{$_},    1, "thread $_ was run once";
  is $called{$_}, 1, "thread $_ destructor was called once";
 }
}

sub cb {
 my ($y, $depth) = @_;

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

 $_->join for spawn $num, $depth - 1;

 check;
}

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

$_->join for spawn $num, $depth;

check;

is $x, -1, '$x in the main thread';

