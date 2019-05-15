# Christian Schubert, Christian.Schubert@tu-dresden.de, 2012-12-17
# CMakefile for compilation of OMC

# include CTest gives more options (such as running valgrind automatically)
include(CTest)

#Define values in the "config.h"
set(CTEST_RETURN_SUCCESS 0)
set(CTEST_RETURN_FAIL 1)

ADD_EXECUTABLE (test_pivot ${CMAKE_CURRENT_SOURCE_DIR}/test_pivot.c )
ADD_TEST(test_simulationruntime_mathsupport_pivot test_pivot)
