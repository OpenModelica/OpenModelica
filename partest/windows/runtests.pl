#!/usr/bin/perl

# Author: Per Östlund
#
# This script parses the makefiles in the testsuite and extracts (almost) all
# testcases. It then runs each test with the runtest.pl script, which creates a
# new directory for each test and symlinks all needed files into that directory.
# In this way it's possible to run all tests in parallel, which greatly speeds
# up testing when using more than two processor cores.
#
# Usage: Run without any arguments to run the whole testsuite, or with -f to
#        run a fast test, i.e. skipping the libraries directory.
#
# NOTE: This is not the official OpenModelica way of running the testsuite, so
#       you should run a 'make test' before committing any changes just to make
#       sure that this script doesn't miss anything.
#
# NOTE: This script has only been tested on Linux so far, and will probably not
#       work under any other platform without some modifications.
#
# TODO: MetaModelicaDev in meta is not run yet, since those tests are organized
#       a bit differently.

use strict;
use warnings;

use threads;
use threads::shared;
use Thread::Queue;
use Term::ANSIColor;
use List::Util 'shuffle';
use Cwd;
use File::Path qw(rmtree);
use Time::HiRes qw( usleep gettimeofday tv_interval );
use Fcntl;

sub mysymlink
{
   my $source = shift(@_);
   my $dest   = shift(@_);
   system("ln -s " . $source . " " . $dest);
}

my $use_db = 1;
my $nocolour = '';
my $fast = 0;

# Default is two threads.
my $thread_count = 2;
my $check_proc_cpu = 1;
my $withxml = 0;
my $withxmlcmd = 0;

# Check for the -f flag.
for(@ARGV){
  if(/-f/) {
    $fast = 1;
  }
  elsif(/-j([0-9]+)/) {
    $check_proc_cpu = 0;
    $thread_count = $1;
  }
  elsif(/-nodb/) {
    $use_db = 0;
  }
  elsif(/-nocolour/) {
    $nocolour = '--no-colour';
  }
  elsif(/-with-xml/) {
    $withxml = 1;
    $withxmlcmd = '-with-xml';
  }
}

if ($use_db) {
  eval { require MLDBM; 1; };

  if(!$@) {
    MLDBM->import();
  } else {
    print "Could not load MLDBM module, falling back to nodb mode.\n";
    $use_db = 0;
  }
}

my @test_list;
my $test_queue = Thread::Queue->new();
my $tests_failed :shared = 0;
my @failed_tests :shared;
my $testscript = cwd() . "/runtest.pl";
my $testsuite_root = cwd() . "/../";
my %test_map :shared;

if($use_db) {
  tie (my %db_map, "MLDBM", "../runtest.db", O_RDWR|O_CREAT, 0664);
  %test_map = %db_map;
}

# Parse a makefile
sub read_makefile {
  my $dir = shift;

  return if $dir eq "./java"; # Skip the java tests, since they don't work.
  return if($fast == 1 and $dir =~ m"^./libraries"); # Skip libraries if -f is given.
  return if($fast == 1 and $dir eq "./bootstrapping"); # Skip libraries if -f is given.
  return if($fast == 1 and $dir eq "./metamodelica"); # Skip libraries if -f is given.
  return if($fast == 1 and $dir =~ m"^./3rdParty"); # Skip libraries if -f is given.

  open(my $in, "<", "$dir/Makefile") or die "Couldn't open $dir/Makefile: $!";

  while(<$in>) {
    if(/(\S+) -f Makefile test[^s]/) {  # Recursively parse makefiles.
      read_makefile("$dir/$1");
    }
    elsif(/^TESTFILES.*=.*$/) { # Found a list of tests, parse them.
      seek($in, -length($_), 1);
      parse_testfiles($in, $dir);
    }
  }
} 

# Parse a list of tests given in a makefile by TESTFILES.
sub parse_testfiles {
  my $in = shift;
  my $path = shift;

  while(<$in>) {
    add_tests($_, $path) unless /#.*/; # Skip lines beginning with #
    last unless /\\/; # If the line doesn't end with \, stop.
  }
}

# Extract all files beginning with .mo|.mof|.mos from a line.
sub add_tests {
  my @tests = split(/\s|=|\\/, shift);
  my $path = shift;

  @tests = grep(/\.mo|\.mof|\.mos/, @tests);
  @tests = map { $_ = "$path/$_" } @tests; 

  push @test_list, @tests;
}

# Run the tests by dequeuing them from the list of tests and calling the
# runtest.pl script.
sub run_tests {
  while(defined(my $test_full = $test_queue->dequeue_nb())) {
    (my $test_dir, my $test) = $test_full =~ /(.*)\/([^\/]*)$/;

    my $t0 = [gettimeofday];
    my $cmd = "$testscript $test_full $nocolour $withxmlcmd";
    my $x = system("$cmd") >> 8;
    my $elapsed = tv_interval ( $t0, [gettimeofday]);

    if($use_db) {
      lock(%test_map);
      $test_map{$test_full} = $elapsed;
    }

    if($x == 0) { # Add the test to the list of failed tests if it failed.
      lock($tests_failed);
      $tests_failed++;
      lock(@failed_tests);
      push @failed_tests, $test_full;
    }
  }
}

# Assume that we are in a subdirectory of the testsuite, so go up one level and
# parse the makefile there.
chdir("..");
read_makefile(".");


if($use_db) {
  # Sort most expensive operations first
  @test_list = reverse @test_list;
  @test_list = sort {
    my $la = $test_map{$a};
    my $lb = $test_map{$b};
    $la = defined($la) ? $la : 20;
    $lb = defined($lb) ? $lb : 20;
    $lb <=> $la
  } @test_list;
}

foreach(@test_list) {
  $test_queue->enqueue($_);
}

# Check if we can open /proc/cpuinfo to see how many cores are available, and
# use that many threads instead.
if ($check_proc_cpu and open(my $in, "<", "/proc/cpuinfo")) {
  $thread_count = 0;

  while(<$in>) {
    $thread_count++ if /processor/;
  }
}
print "$thread_count threads\n";

# Make sure that omc-diff is generated before trying to run any tests.
system("make -C difftool > /dev/null 2>&1");

#mysymlink('../Compiler', 'Compiler');

# Run the tests by calling the run_tests function with multiple threads.
for(my $i = 0; $i < $thread_count; $i++) {
  threads->create(\&run_tests);
}

# Wait for the tests to finish.
foreach my $thr (threads->list()) {
  $thr->join();
}

# Print out the list of tests that failed, and a summary of how many failed.
print color 'reset';
print "\n";

if(@failed_tests) {
  print "\nFailed tests:\n";

  foreach my $failed_test (@failed_tests) {
    print "\t" . $failed_test . "\n";
  }
}

my $test_count = @test_list;
print "\n$tests_failed of $test_count failed\n";

if($use_db) {
  tie (my %db_map, "MLDBM", "runtest.db", O_RDWR|O_CREAT, 0664);
  %db_map = %test_map;
}

# Read the files in serial; seems to get issues otherwise
if($withxml) {
  unlink("result.xml");
  unlink("partest/result.xml");
  open my $XMLOUT, '>', "$testsuite_root/partest/result.xml" or die "Couldn't open result.xml: $!";
  binmode $XMLOUT, ":encoding(UTF-8)";
  print $XMLOUT "<testsuite>\n";

  foreach(@test_list) {
    my $test_full = $_;
    (my $test_dir, my $test) = $test_full =~ /(.*)\/([^\/]*)$/;
    my $filename = "$testsuite_root$test_full.result.xml";
    
    my $data = "";
    if (open my $fh, '<', $filename) {
      $data = do { local $/; <$fh> };
    }
    if ($data !~ m,^<testcase.*>, || $data !~ m,</testcase>,) {
      my $classname = $test_dir;
      # Replace ./abc/def with abc.def
      $classname =~ s,\./,,g;
      $classname =~ s,/,.,g;
      print "\nERROR: Result xml not found: $filename. Cwd is: ".cwd(). "data is: $data\n";
      $data = "<testcase classname=\"$classname\" name=\"$test\"><failure type=\"Result not found\">Result xml-file not found</failure></testcase>";
    }
    print $XMLOUT "$data";
  }

  print $XMLOUT "</testsuite>\n";
}

#unlink("Compiler");
# Clean up the temporary rtest directory, so it doesn't get overrun.
rmtree(glob "/tmp/omc-rtest*");

if(@failed_tests && !$withxml) {
  exit 7;
}
