set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Specify the cross compiler
set(CMAKE_C_COMPILER   arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)
set(CMAKE_Fortran_COMPILER arm-linux-gnueabihf-gfortran)

# Set the search paths for libraries and includes
set(CMAKE_FIND_ROOT_PATH
  /usr/lib/arm-linux-gnueabihf
  /usr/include/arm-linux-gnueabihf)

# Set path to FindBoost.cmake
set(Boost_DIR
  /usr/lib/arm-linux-gnueabihf/cmake/Boost-1.74.0/)

# Only search in target paths for libraries and includes
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# FFI tests binaries break when cross-compiling
set(HAVE_MMAP_DEV_ZERO 0)
set(HAVE_ALLOCA 0)
