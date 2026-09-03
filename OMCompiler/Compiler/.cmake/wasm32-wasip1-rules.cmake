# How a wasm32-wasip1 target is named and linked. Reached through the toolchain
# file's CMAKE_USER_MAKE_RULES_OVERRIDE, the only hook CMake includes after
# Platform/WASI.cmake, which a module of ours cannot shadow.

# `Library="foo"` resolves to a module omc loads, not a library a linker reads.
set(CMAKE_SHARED_LIBRARY_SUFFIX ".wasm")
set(CMAKE_SHARED_MODULE_SUFFIX ".wasm")
set(CMAKE_EXECUTABLE_SUFFIX ".wasm")

foreach(lang C CXX)
  set(CMAKE_SHARED_LIBRARY_${lang}_FLAGS "-fPIC")
  set(CMAKE_SHARED_LIBRARY_CREATE_${lang}_FLAGS "-shared")
  set(CMAKE_SHARED_MODULE_CREATE_${lang}_FLAGS "-shared")
  # wasm-ld has neither -soname nor a runtime search path.
  unset(CMAKE_SHARED_LIBRARY_SONAME_${lang}_FLAG)
  unset(CMAKE_SHARED_LIBRARY_RUNTIME_${lang}_FLAG)
endforeach()
set(CMAKE_PLATFORM_NO_VERSIONED_SONAME 1)
