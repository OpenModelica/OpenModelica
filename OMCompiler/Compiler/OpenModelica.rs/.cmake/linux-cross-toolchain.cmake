# Cross-compile OpenModelica's C/C++ to another Linux architecture with the
# distribution's own GNU cross toolchain and its multiarch target libraries
# (build-deps' qt-aarch64-linux add-on installs both).
#
#   cmake -S . -B build-arm64 \
#     -DCMAKE_TOOLCHAIN_FILE=OMCompiler/Compiler/OpenModelica.rs/.cmake/linux-cross-toolchain.cmake \
#     [-DLINUX_CROSS_ARCH=aarch64]
#
# Unlike the Windows and macOS toolchains there is no sysroot and no wrapper:
# multiarch puts the target's libraries in /usr/lib/<triple> on the build host
# itself, so CMAKE_LIBRARY_ARCHITECTURE is what keeps find_library() off the
# host's own. A real gfortran exists for these targets, so nothing here has to
# give up MOO or the optimization module the way the flang-linked targets do.

if(NOT LINUX_CROSS_ARCH)
  set(LINUX_CROSS_ARCH aarch64)
endif()

if(LINUX_CROSS_ARCH STREQUAL "aarch64" OR LINUX_CROSS_ARCH STREQUAL "arm64")
  set(CMAKE_SYSTEM_PROCESSOR aarch64)
  set(_linux_cross_triple aarch64-linux-gnu)
else()
  message(FATAL_ERROR "LINUX_CROSS_ARCH=${LINUX_CROSS_ARCH} is not wired; only aarch64 is.")
endif()

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_LIBRARY_ARCHITECTURE ${_linux_cross_triple})
# Only needs to be non-empty, and cross-compiling leaves it unset: 3rdParty/libzmq
# dereferences it unquoted, which malforms its if() into "Unknown arguments".
# darwin-toolchain.cmake sets it for the same reason.
if(NOT CMAKE_SYSTEM_VERSION)
  set(CMAKE_SYSTEM_VERSION 1)
endif()

set(CMAKE_C_COMPILER ${_linux_cross_triple}-gcc)
set(CMAKE_CXX_COMPILER ${_linux_cross_triple}-g++)
set(CMAKE_Fortran_COMPILER ${_linux_cross_triple}-gfortran)

# Deliberately no CMAKE_FIND_ROOT_PATH. The Windows and macOS toolchains have a
# sysroot to confine find_*() to; multiarch does not -- the target's libraries
# are installed on the build host itself, and its headers are the host's own in
# /usr/include. Confining the search then hides libraries the project builds in
# its own build tree, which is how SUNDIALS' Fortran name-mangling probe fails
# (it find_library()s the libflib.a it just compiled). CMAKE_LIBRARY_ARCHITECTURE
# above is what actually steers find_library() to /usr/lib/<triple>, which CMake
# searches ahead of the host's own.

# pkg-config otherwise answers with the host's .pc files, whose -L and -I point
# at x86-64 directories that link but do not load.
set(ENV{PKG_CONFIG_LIBDIR} "/usr/lib/${_linux_cross_triple}/pkgconfig:/usr/share/pkgconfig")
set(ENV{PKG_CONFIG_PATH} "")
