#!/usr/bin/perl
# Usage: convert_lines.pl inFile outFile
# The new file adds a #line directive to each existing line, using the comment
# in OpenModelica generated C code on the format /*#modelicaLine ABC.mo:12:13-12:14*/
# This makes it possible to use GDB with OMC generate source code. It will also
# make GCC errors spit out Modelica line numbers instead of C lines, which helps a lot.
# -- martin.sjolund@liu.se

use Cwd;
use Cwd 'abs_path';

sub trim{
   my $string = shift;
   $string =~ s/^\s+|\s+$//g;
   return $string;
}

$inf = $ARGV[0];
$outf = $ARGV[1];
open(INP, "<$inf")  or die("Cannot open file '$inf' for reading\n");
open(OUTP, ">$outf") or die("Cannot open file '$outf' for writing\n");

$lnum = 1;
$inStmt = 0;
$inStmtFile = "";
$inStmtLine = 0;
while( $line = <INP> ){
  $trimmedLine = trim($line);
  # regex is fun
  # handles file paths like /c/Test/foo.mo, c:/Test/foo.mo, c:\Test\foo.mo
  if ($trimmedLine =~ /^ *..#modelicaLine .([A-Za-z0-9.\/\\:]*):([0-9]*):[0-9]*-[0-9]*:[0-9]*...$/) {
    eval {
    if ($^O eq "msys") {
      $myString = $1;
      $myString =~ s/\\/\//g; # convert back slashes to forward slashes
      # split the file location
      my @values = split('/', $myString);
      # read the filename
      $fileName = pop(@values);
      # join the file location back
      if (scalar(@values) > 0) {
        $fileLocation = join('/', @values);
        $inStmtFile = abs_path($fileLocation); # Absolute paths makes GDB a _lot_ happier;
        $inStmtFile = $inStmtFile.'/'.$fileName;
      } else {
        $inStmtFile = abs_path($myString);
      }
    } else {
      $inStmtFile = abs_path($1); # Absolute paths makes GDB a _lot_ happier;
    }
  };
  if ($@) {
    $dir = getcwd();
    $inStmtFile = $dir + "/" + $1;
  }
    $inStmtLine = $2;
    $inStmt = 1;
  } elsif ($line =~ /^ *..#endModelicaLine/) {
    $inStmt = 0;
  } elsif ($inStmt) {
    print OUTP "#line $inStmtLine \"$inStmtFile\"\n$line";
  } else {
    print OUTP "#line $lnum \"$inf\"\n$line";
  }
  $lnum++;
}

close INP;
close OUTP;
