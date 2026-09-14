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

Test discovery/filtering is delegated entirely to `runtests.pl` (see
`Partest/GenerateCTestFile.cmake`), so it only ever picks up tests from under
`testsuite/`, and the resulting CTest test list matches what an unpartitioned
`partest` run would use, in the same order. That makes splitting the
testsuite into reproducible shards a plain CTest `-I <M>,,<N>` (every `N`th
test starting at test `M`), instead of `runtests.pl -partition=<M>/<N>`.

Because a CTestTestfile.cmake bakes in absolute paths, and because the CI
stages that need this only unstash an installed `omc` rather than a
configured build tree, the file is generated on demand with `cmake -P`
instead of via the normal project configure:

```sh
cmake -DTESTSUITE_DIR="$PWD/testsuite" -DOUTPUT_DIR="$PWD/build-testsuite-ctest" \
      -P testsuite/CTest/Partest/GenerateCTestFile.cmake

ctest --test-dir build-testsuite-ctest -I 1,,3 --output-on-failure
```

See `ctestCMakeStashed()` in `.CI/common.groovy` for how Jenkins' CMake
testsuite stages use this.
