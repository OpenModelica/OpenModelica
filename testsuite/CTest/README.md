# Experimental CTest

Use
[CTest](https://cmake.org/cmake/help/book/mastering-cmake/chapter/Testing%20With%20CMake%20and%20CTest.html)
for a few functions to see the capabilities of CTest.

## Build and run tests

You need the target `ctestsuite-depends` to build the tests and `test` to actually run them.
So run these commands:

```bash
cmake --build build_cmake --target ctestsuite-depends --parallel
cmake --build build_cmake --target test
```

## Add tests

The tests are using the testing framework
[GoogleTest](https://github.com/google/googletest).

### GoogleTest

Needs at least C++ 17 for GoogleTest.
