#!/usr/bin/perl

use strict;
use warnings;

if($#ARGV < 0) {
  print "Usage: validatetest.pl testcase.\n";
  exit 0;
}

my $test = $ARGV[0];
my $OMHOME = $ENV{OPENMODELICAHOME};
my @output;
my @expected_output;

# Check that the test case actually exists.
unless(-e $test) {
  print "Test case $test does not exist!\n";
  exit -1;
}

# Run omc on the test case and redirect the output to the @output list.
open TESTRUN, "'$OMHOME'/bin/omc -- --running-testsuite $test |" or die "Failed to open pipeline";
while(<TESTRUN>) {
  push @output, $_;
}

# Open the test case and read the expected output into the @expected_output list.
open TESTCASE, "<", $test or die "Couldn't open $test, did it delete itself?";
# Read until we find the result section.
while(<TESTCASE>) {
  last if /\s*\/\/\s*Result:\s*$/;
}
while(<TESTCASE>) {
  # Stop once we reach endResult.
  last if /\s*\/\/\s*endResult\s*$/;

  # Strip the // before each line and push it into @expected_output.
  if(/\/\/ (.*)/) {
    push @expected_output, "$1\n";
  }
}

# Sort both lists.
@output = sort @output;
@expected_output = sort @expected_output;

# Go through each line in the output. For each line, search the expected output
# for an equivalent line and delete both if found. If the output matches the
# expected output the result will be two empty lists, otherwise any excess or
# missing output will be left in the lists.
my $eoi = 0;
for(my $i = 0; $i <= $#output; $i++) {
  for(; $eoi <= $#expected_output; $eoi++) {
    my $so = $output[$i];
    my $seo = $expected_output[$eoi];
    # trim the crap (windows/linux line endings and stuff)
    $so =~ s/^\s+|\s+$//g;
    $seo =~ s/^\s+|\s+$//g;
    if ($so eq $seo) {
      splice @expected_output, $eoi, 1;
      splice @output, $i, 1;
      $i--;
      last;
    } 
    elsif ($so lt $seo) {
      last;
    }
  }
}

# Print the result.
if(@output or @expected_output) {
  if(@output) {
    print "Excess output [" . scalar(@output) . "]:\n";
    print @output;
  }
  if(@expected_output) {
    print "Missing output [" . scalar(@expected_output) . "]:\n";
    print @expected_output;
  }
  print "Update testcase? y/N\n";
  chomp(my $input = <STDIN>);

  if($input eq "y") {
    print "Updating test case...\n";
    system("'$OMHOME'/../testsuite/rtest -b $test");
    print "Test case updated.\n";
  }
} else {
  print "Output matching, updating test case...\n";
  system("'$OMHOME'/../testsuite/rtest -b $test");
  print "Test case updated.\n";
}
