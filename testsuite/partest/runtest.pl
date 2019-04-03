#!/usr/bin/perl

# Author: Per Östlund
#
# This script runs a testcase, usually given to it by the runtests.pl script.

use strict;
use warnings;
use Cwd;
use Term::ANSIColor;
use File::Path qw(rmtree);
use Encode qw(decode encode);

# Get the testcase to run from the command line argument.
my $test_full = $ARGV[0];
my $no_colour = 0;
my $withxml = 0;
my $rtest_extra_args = "";
my $test_baseline = 0;

for(@ARGV){
  if(/--no-colour/) {
    $no_colour = 1;
  }
  elsif(/-with-xml/) {
    $withxml = 1;
  }
  elsif(/-have-dwdiff/) {
    $rtest_extra_args = $rtest_extra_args . " -c";
  }
  elsif(/^--with-omc=(.*)$/) {
    $rtest_extra_args = $rtest_extra_args . " --with-omc=$1";
  }
  elsif(/-b/) {
    $rtest_extra_args = $rtest_extra_args . " -b";
	$test_baseline = 1;
  }
}
#if($no_colour) {
#  $rtest_extra_args = "";
#}

# Extract the directory and test name.
(my $test_dir, my $test) = $test_full =~ /(.*)\/([^\/]*)$/;
# Add a random number to the temporary directory, to avoid problems with rtest
# when we have two test cases with the same name in different directories.
my $test_id = int(rand(9999));
# Build the full path to the temporary directory to run the test in.
my $tmp_path_full = $test_dir . "/" . $test . "_temp" . $test_id;

# Makes a symbolic link to a file.
sub make_link {
  my $file = shift;

  # Depending on how the path is given we need to use different rules for how
  # the symlink should be created.
  for ($file) {
    if    (/\.\.\/(\w*)\/package.mo/) { symlink("../" . $1, "../" . $1); }
    elsif (/\.\/(\w*)\/package.mo/)   { symlink("../" . $1, $1); }
    elsif (/\.\.\/([\w-]*)\//)        { symlink("../" . $1, "../" . $1); }
    elsif (/^(\w*)\/(.*)/)            { symlink("../" . $1, $1); }
    elsif (/(.*)/)                    { symlink("../" . $1, $1); }
    else                              { symlink("../" . $file, $file); }
  }
}

# Some tests use libraries that we need to symlink the corresponding headers for.
sub lib_to_header {
  my $lib = shift;

  for ($lib) {
    if    (/lib(\w*)\.\w*/)  { return $1 . ".h"; }
    elsif (/(\w*)\.lib/)     { return $1 . ".h"; }
    else  { return ""; }
  }
}

# Some tests needs some special symlinks that are hard to determine by just
# parsing the test-scripts, so this functions applies a couple of special rules.
sub make_test_specific_links {
  if (-d "../ReferenceFiles") {
    make_link("ReferenceFiles");
  }
  if (-d "../ReferenceGraphs") {
    make_link("ReferenceGraphs");
  }

  # search for any _prof.xml and _TaskGraph.graphml and link those too
  my $dir = '../';
  opendir(DIR, $dir);
  while (my $file = readdir(DIR)) {
    # We only want files
    next unless (-f "$dir/$file");
    # Use a regular expression to find files ending in _prof.xml and _TaskGraph.graphml
    next unless ($file =~ m/_prof\.xml$/) or ($file =~ m/_TaskGraph\.graphml$/);
    make_link($file);
  }
  closedir(DIR);
}

sub remove_test_specific_links {
  my %links = (
    "ParseModel.mos" => ["ParseModel.mo"]
  );

  map { unlink($_) } @{$links{"ParseModel.mos"}};
}

# This functions sets up a sandbox for a tests by creating a temporary directory
# and symlinking the needed files into it.
sub enter_sandbox {
  mkdir($tmp_path_full);
  chdir($tmp_path_full);
  make_link($test);
  make_test_specific_links();

  # Parse the testscript to see if it has any special requirements.
  my $open_ret = open(my $in, "<", $test);

  unless($open_ret) {#or die "Couldn't open $test: $!\n";
    print " ";
    if ($no_colour) {
      print "[$test] FAILED\n";
    } else {
      print color 'red on_blue';
      print "[$test]";
      print color 'reset';
    }
    exit_sandbox();
    exit 0;
  }

  my $stop_expr;

  # If we are parsing a mos-file, stop when we reach 'Result:'. Otherwise, parse
  # until we reach a line that's not a comment.
  if(substr($test, -3) eq "mos") {
    $stop_expr = "// Result:";
  } else {
    $stop_expr = "^[^/]";
  }

  # Check for a couple of keywords such as loadFile, and create the neccessary
  # symlinks.
  while(<$in>) {
    if    (/$stop_expr/)               { last; }
    elsif (/setup_command.*\s(.*\.c)/) { make_link($1); }
    elsif (/depends: *([A-Za-z0-9_.-]*)/) { make_link($1); }
    elsif (/loadFile.*\(\"linear_simple_test\.mo\"\)/) {}
    elsif (/loadFile.*\(\"(.*)\"\)/)   { make_link($1); }
    elsif (/runScript.*\(\"(.*)\"\)/)  { make_link($1); }
    elsif (/importFMU.*\(\"(.*)\"\)/)  { make_link($1); }
    elsif (/partest-link: *([A-Za-z0-9.]*)/) { make_link($1); }
    elsif (/system\(\"(gcc|g\+\+).*\s(\w*\.\w*)\s(\w*\.\w*)/) {
      my $header = lib_to_header($2);
      make_link($header);
      make_link($3);
    }
    elsif (/system\(\"(gcc|g\+\+).*\s(\w*\.\w*)/) {
      make_link($2);
    }
    elsif (/external.*\\\"(.*\.h)\\\"/){
      make_link($1);

      while(<$in>) {
        if(/end (.*);/) {
          make_link($1 . ".c");
          last;
        }
      }
    }
    elsif (/env:\s*OPENMODELICALIBRARY\s*=\s*(.*)/) {
      my $lib = $1;
      $lib =~ s/((?:\.\.\/)+)/..\/$1/g;
      $ENV{'OPENMODELICALIBRARY'} = $lib;
    }
  }

  remove_test_specific_links();
}

# Exit the sandbox by going up one directory level and delete the temporary
# directory.
sub exit_sandbox {
  chdir("..");

  # Hack to get RunScript working.
  sleep 1 if $test eq "RunScript.mos";

  rmtree($test . "_temp" . $test_id);
}

sub needs_sandbox {
  if ($test eq "CheckSourcesForTabs.mos") { return 0; }
  if ($test eq "testCompileInteractive.mos") { return 0; }
  return 1;
}

$ENV{'PATH'} = "./:" . $ENV{'PATH'};

# Some tests are hard to sandbox and don't really need to be, so skip sandboxing
# for those tests.
my $sandbox_needed = needs_sandbox();

enter_sandbox() if $sandbox_needed;
chdir($test_dir) if !$sandbox_needed;

my $fail_log = ($sandbox_needed ? "../" : "") . "$test.fail_log";
my $xml_log = ($sandbox_needed ? "../" : "") . "$test.result.xml";

# Clean up fail logs from previous runs.
unlink("$fail_log");
unlink("$xml_log") if $withxml;

# Determine the full path to rtest.
my $n = ($test_full =~ tr/\///) - ($sandbox_needed ? 0 : 1);
my $test_suit_path_rel = "../" x $n;

my $rtest = $test_suit_path_rel . "rtest $rtest_extra_args -v -nolib ";

# Run the testscript and redirect output to a logfile.
my $cmd = "$rtest $test > $test.test_log 2>&1";
system("$cmd");

# Read the logfile and see if the test succeeded or failed.
open(my $test_log, "<", "$test.test_log") or die "Couldn't open test log $test.log: $!\n";

my $exit_status = 1;
my $erroneous = 0;
my $time = 0;
my $nfailed = 1;

while(<$test_log>) {
  if(/\.\.\. erroneous/) {
    $erroneous = 1;
  }
  elsif(/== (\d) out of 1 tests failed.*time: (\d*)/) {
    $nfailed = $1;
    $time = $2;
  }
  elsif(/== Failed to set baseline.*time: (\d*)/) {
    $nfailed = 1;
    $time = $2;
  }  
  elsif(/.*time: (\d*)/) {
    $nfailed = 0;
    $time = $1;
  }
}

if (!$no_colour) {
  if($nfailed =~ /0/) {
    if ($test_baseline) {
	  print color 'blue';
	} else {
      print color 'green';
	}
  } else {
    if($erroneous == 0) {
      system("cp $test.test_log $fail_log");
      print color 'red';
      $exit_status = 0;
    } else {
      system("cp $test.test_log $fail_log");
      print color 'magenta';
    }
  }
  print " ";
}
if ($test_baseline) {
  print "[Baselining $test:$time]";
} else {
  print "[$test:$time]";
}
if ($no_colour) {
  if($nfailed =~ /0/) {
    print " OK\n";
  } else {
    if($erroneous == 0) {
      system("cp $test.test_log $fail_log");
      print " Failed\n";
      $exit_status = 0;
    } else {
      system("cp $test.test_log $fail_log");
      print " Erroneous\n";
    }
  }
} else {
  print color 'reset';
}

if ($withxml) {
  my $XMLOUT;
  open $XMLOUT, '>', $xml_log or die "Couldn't open result.xml: $!";
  binmode $XMLOUT, ":encoding(UTF-8)";
  my $classname = $test_dir;
  # Replace ./abc/def with abc.def
  $classname =~ s,\./,,g;
  $classname =~ s,/,_,g;

  print $XMLOUT "<testcase classname=\"$classname\" name=\"$test\" time=\"$time\">";
  if ($erroneous == 1) {
    print $XMLOUT '<skipped />';
  }
  elsif ($exit_status == 0) {
    print $XMLOUT '<failure type="Failure">Output mismatch (see stdout for details)</failure>';
    print $XMLOUT '<system-out>';
    open my $fh, '<', $fail_log;
    my $data;
    if (!$fh) {
      $data = 'Unknown result';
    } else {
      $data = do { local $/; <$fh> };
      # Convert illegal characters in the UTF-8 stream into valid UTF-8 character question mark (�)
      $data = decode('UTF-8', $data, Encode::FB_DEFAULT);
      $data = encode('UTF-8', $data, Encode::FB_CROAK);
      $data =~ s/&/&amp;/g;
      $data =~ s/</&lt;/g;
      $data =~ s/>/&gt;/g;
      $data =~ s/"/&quot;/g;
      $data =~ s/'/&apos;/g;
      # Remove non printable characters as they are not valid xml
      $data =~ s/[^[:print:]\n]+//g;
    }
    print $XMLOUT $data;
    print $XMLOUT '</system-out>';
  }
  print $XMLOUT "</testcase>\n";
  close $XMLOUT;
}

exit_sandbox() if $sandbox_needed;

if ($exit_status == 0) {
  exit 0;
} else {
  if ($time < 1) {
    exit 1;
  } elsif ($time > 100) {
    exit 100;
  }
  exit $time;
}

