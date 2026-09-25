/*
 * RCS: $Id: README.txt 22008 2014-08-26 23:13:07Z hudson $
 */

Building
------------------------------
- The GDBMIParser is built as part of the normal CMake build of OpenModelica on
  all platforms; there is no separate build step.
- GDBMIParser.cpp/.h are generated from GDBMIOutput.g with ANTLR3 and are
  checked in, so ANTLR3 is not needed to build OpenModelica.

------------------------------
Adeel.
adeel.asghar@liu.se
