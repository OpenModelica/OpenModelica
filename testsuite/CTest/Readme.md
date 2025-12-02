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
