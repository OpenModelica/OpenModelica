# Tips for the testsuite

## 1 - Creating test files

To get a correct testfile, watch out for use of tab and space, can be hard to find. If rtest fails but the single file actually translates with omc the check the log file in the /tmp directory.

Templates for writing testfiles are:
* mofiles/translation_template.mo
* mofiles/translation_failed_template.mo
* mosfiles/simulation_template.mos
* mosfiles/simulation_failed_template.mos

rtest special directives added to help creating testcases:
* cflags: +d=xyz  
  Will insert the text as arguments to omc.  
  Useful if you e.g. want to disable compiling functions with gcc while you flatten code.  
  You can also set the environment variable RTEST_OMCFLAGS if you want to insert these flags for all commands you run.
* setup_command: gcc ...  
  Will execute the provided command before running omc.
* teardown_command: rm -f ...  
  Will execute the provided command after running omc.

**NOTE**:  
A test MUST have the finishing "end ..." at the same indentation level as the "model ..." otherwise there will be a warning(perl -w rtest file) for the next test that are executed.

NEVER do this:
```
// flclass ...
//    ...
//    end flclass ...;
```
Do this:
```
// flclass ...
//    ...
// end flclass ...;
```
Then perl is happy. (no warnings and errornously failed testcases).

**If you add any files that are not '*.mo', '*.mos' or 'Makefile', don't forget to add them to the Makefile @DEPENDENCIES**

## 2 - Creating test folders

1. Create your folder.
2. Copy the file Makefile_sample.txt to your directory. Rename it to Makefile.
3. Add your test files (*.mo and *.mos) -> @TESTFILES
4. Add any failing tests -> @FAILINGTESTFILES
5. Add any other files that are needed (e.g. C files with external functions ...) at -> @DEPENDENCIES  
   If you have many dependency files then add them to the directory and just run "make getdeps"  
   This will give you the list of files in 'deps.txt'. Copy the list it as it is.
2. Add the folder


## 3 - Running the testsuite

The testsuite consists of modelica files (.mo) and modelica script files (.mos) in the directories mofiles and mosfiles.

1. `make`  
   Will make all tests that currently should pass. Use this before checking in.

2. `rtest` in directory mofiles  
   Will run all tests in the directory, including tests that does not pass.

3. `make failingtest` runs the tests that is added but not in the testsuite since they fail, i.e. not implemented in OMC yet.

4. `make clean` will clean all temporary files in each folder in the testsuite.

last modified:
	2012-03-01, Mahder.Gebremedhin@liu.se
