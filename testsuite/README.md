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
  A command that builds an external "C" library should not name a compiler
  directly; use the variables rtest exports so the test also works for the
  wasm-jit target, which needs the library as a PIC dylink `.wasm` module
  rather than a host object file:

      // setup_command: $OMC_CC $OMC_CFLAGS $OMC_EXTLIB_FLAGS -o foo$OMC_EXTLIB_EXT foo.c $OMC_EXTLIB_LIBS

  | Variable | Default | wasm-jit |
  | --- | --- | --- |
  | `OMC_CC` | `gcc` | `clang --target=wasm32-wasip1 --sysroot=$OPENMODELICAHOME/lib/wasm32-wasi/omc` |
  | `OMC_CFLAGS` | `-fPIC` | `-fPIC` |
  | `OMC_EXTLIB_FLAGS` | `-c` | `-shared -nodefaultlibs -Wl,--export-all -Wl,--allow-undefined` |
  | `OMC_EXTLIB_LIBS` | (empty) | the wasm32 compiler-rt builtins archive |
  | `OMC_EXTLIB_EXT` | `.o` | `.wasm` |
  | `OMC_AR` | `ar` | `true` (a dylink module is already linked) |

  Each is taken from the environment when already set, so a run can point them
  at another toolchain. The wasm values are used when the target under test is
  wasm-jit (`OPENMODELICA_TEST_SIMCODETARGET` or `--simCodeTarget=` in
  `RTEST_OMCFLAGS`).
* teardown_command: rm -f ...  
  Will execute the provided command after running omc.
* suite: metamodelica, 63bit  
  Puts the test in one or more test suites, so that a run which cannot support
  them can deselect it: `partest/runtests.pl -suites=-metamodelica,-63bit`.
  Run `runtests.pl -h` for the suites and their defaults. The directive must be
  in the test's header, i.e. before the first line of code.
* suite: wasm — says that the test selects the `wasm-jit` or `wasm` simCodeTarget
  itself (rather than running under whatever target the run was given). Only the
  Rust omc implements those targets, so the suite is off by default and the Rust
  partest turns it on with `-suites=+wasm`. `rtest test.mos` runs such a test
  regardless, as it does for the other tag suites.
* suite: disabled — says that the test is not part of the testsuite, i.e. that it
  is listed in its makefile as a failing, not compiling, not simulating or manual
  test rather than in `TESTFILES`. Such a test is expected to fail, and some of
  them hang or eat all the memory of the machine, so nothing runs it unless asked
  to:
  * `rtest -disabled test.mos` (or `RTEST_RUN_DISABLED=1`) runs it anyway,
    otherwise rtest reports it as `disabled` and neither passes nor fails it.
  * `make failingtest` and the other makefile targets for these lists pass
    `-disabled` themselves.
  * `partest/runtests.pl -failing` (or `-suites=+disabled`) runs them.

  Every test listed in a makefile outside `TESTFILES` carries this tag; keep the
  two in sync when a test is enabled or disabled.

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
4. Add any failing tests -> @FAILINGTESTFILES, and mark each of them with
   `// suite: disabled` in its header
5. Add any other files that are needed (e.g. C files with external functions ...) at -> @DEPENDENCIES  
   If you have many dependency files then add them to the directory and just run "make getdeps"  
   This will give you the list of files in 'deps.txt'. Copy the list it as it is.
2. Add the folder


## 3 - Running the testsuite

The testsuite consists of modelica files (.mo) and modelica script files (.mos) in the directories mofiles and mosfiles.

1. `make`  
   Will make all tests that currently should pass. Use this before checking in.

2. `rtest` in directory mofiles  
   Will run all tests in the directory, except the ones marked `// suite: disabled`.
   Add `-disabled` to run those too.

3. `make failingtest` runs the tests that is added but not in the testsuite since they fail, i.e. not implemented in OMC yet.

4. `make clean` will clean all temporary files in each folder in the testsuite.

last modified:
	2012-03-01, Mahder.Gebremedhin@liu.se
