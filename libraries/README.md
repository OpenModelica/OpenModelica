
## How to add a new library needed by the testsuite

1. add lib to libraries/update.py
2. run `cd libraries && make update`
3. remove libraries/.openmodelica
4. run `cd libraries && make update`
5. commit the changes to a new PR
6. to install the library do run `make testsuite-depends (in build_cmake for cmake build)` or `make libs-for-testing (in top level for make build)`




