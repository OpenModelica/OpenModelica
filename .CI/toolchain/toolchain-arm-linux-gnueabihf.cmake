# toolchain-arm-linux-gnueabihf.cmake

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Define compiler paths
set(triple arm-linux-gnueabihf)
set(CMAKE_C_COMPILER clang)
set(CMAKE_C_COMPILER_TARGET ${triple})
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_CXX_COMPILER_TARGET ${triple})

# Optionally set sysroot or root filesystem
# set(CMAKE_SYSROOT /path/to/sysroot)

# Optionally specify where to find libraries and headers
# set(CMAKE_FIND_ROOT_PATH /path/to/sysroot)
