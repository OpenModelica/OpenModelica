# Experimental CTest

Use
[CTest](https://cmake.org/cmake/help/book/mastering-cmake/chapter/Testing%20With%20CMake%20and%20CTest.html)
for a few functions to see the capabilities of CTest.

You need the target `ctestsuite-depends` to build the tests and `test` to actually run them.
So run these commands:

```sh
cmake --build build_cmake --target ctestsuite-depends --parallel <Nr. of Cores>
cmake --build build_cmake --target test --parallel <Nr. of Cores>
```

## Makefile testsuite (`Partest/`)

An addon that drives the existing Makefile/rtest testsuite (`testsuite/Makefile`,
`testsuite/partest/`) through CTest instead of (or in addition to) `partest`'s
own Perl thread pool, one CTest test per `.mos`/`.mo` test file. It does not
replace the Makefile testsuite: `make -C testsuite` and `partest/runtests.pl`
keep working exactly as before, and are still how the majority of the CI
stages and local development run the tests.

Test discovery, filtering and sharding are delegated entirely to `runtests.pl`
(see `Partest/GenerateCTestFile.cmake`), so it only ever picks up tests from
under `testsuite/`, and the resulting CTest test list matches what the same
`partest` invocation would run, in the same order. `TESTSUITE_PARTITION` and
`TESTSUITE_PARTITION_SUITES` are forwarded to `runtests.pl -partition=` and
`-partition-suites=`; the generated file then holds exactly the tests of that
shard and CTest needs no `-I` of its own.

Sharding is left to `runtests.pl` rather than done with `ctest -I <M>,,<N>`
because shards can run under different suite configurations: the CMake build
has HDF5 and the autotools one does not have `libomc_result`, so the two only
share a subset of the testsuite. `-partition-suites=` names that shared
configuration, and only the tests in it are split between the shards; a test a
shard enables on top of it runs there in full, because no other shard can run
it at all.

Because a CTestTestfile.cmake bakes in absolute paths, and because the CI
stages that need this only unstash an installed `omc` rather than a
configured build tree, the file is generated on demand with `cmake -P`
instead of via the normal project configure:

```sh
cmake -DTESTSUITE_DIR="$PWD/testsuite" -DOUTPUT_DIR="$PWD/build-testsuite-ctest" \
      -DTESTSUITE_PARTITION=1/2 -DTESTSUITE_PARTITION_SUITES=-hdf5,-arrow \
      -P testsuite/CTest/Partest/GenerateCTestFile.cmake

ctest --test-dir build-testsuite-ctest --output-on-failure
```

See `ctestCMakeStashed()` in `.CI/common.groovy` for how Jenkins' CMake
testsuite stages use this, and section 9 of
[README.cmake.md](../../README.cmake.md) for measuring code coverage over a
testsuite run.
