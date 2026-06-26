# Cross-compile OpenModelica's C/C++ to x86_64-pc-windows-msvc with clang-cl +
# lld-link, reusing the MSVC CRT/SDK that cargo-xwin caches (so the C libs are
# ABI-compatible with the Rust omc artifacts). Requires clang-cl, lld-link,
# llvm-lib, llvm-rc on PATH (lld-link may be a symlink to rust-lld). See
# OpenModelica.rs/README.md for usage + setup.

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)
# Some 3rdParty CMake dereferences CMAKE_SYSTEM_VERSION unquoted (malforms if() when empty).
set(CMAKE_SYSTEM_VERSION 10.0)
# No host MSVC redist to discover when cross-compiling.
set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP TRUE)

# xwin has only the release CRT, so always link /MD (no Debug build). CMP0091 NEW
# makes the runtime library a target property.
set(CMAKE_POLICY_DEFAULT_CMP0091 NEW)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")

# Link try_compile checks (so check_function_exists link-tests, e.g. fork() is
# correctly absent) using the release config (the only CRT xwin ships).
set(CMAKE_TRY_COMPILE_CONFIGURATION Release)

# clang-cl's strict PCH validation trips on CMake-regenerated PCH sources.
set(CMAKE_DISABLE_PRECOMPILE_HEADERS ON)

# xwin sysroot: -DXWIN_CACHE_DIR / $XWIN_CACHE_DIR wins (CI should set it); else
# probe, preferring $CARGO_HOME (Jenkins) over $XDG_CACHE_HOME / $HOME.
if(NOT XWIN_CACHE_DIR)
  if(DEFINED ENV{XWIN_CACHE_DIR})
    set(XWIN_CACHE_DIR "$ENV{XWIN_CACHE_DIR}")
  else()
    set(_xwin_candidates "")
    if(DEFINED ENV{CARGO_HOME})
      list(APPEND _xwin_candidates "$ENV{CARGO_HOME}/xwin")
    endif()
    if(DEFINED ENV{XDG_CACHE_HOME})
      list(APPEND _xwin_candidates "$ENV{XDG_CACHE_HOME}/cargo-xwin/xwin")
    endif()
    list(APPEND _xwin_candidates "$ENV{HOME}/.cache/cargo-xwin/xwin")
    list(GET _xwin_candidates 0 XWIN_CACHE_DIR)
    foreach(_c ${_xwin_candidates})
      if(EXISTS "${_c}/crt/include")
        set(XWIN_CACHE_DIR "${_c}")
        break()
      endif()
    endforeach()
  endif()
endif()
if(NOT EXISTS "${XWIN_CACHE_DIR}/crt/include")
  message(FATAL_ERROR
    "xwin sysroot not found at ${XWIN_CACHE_DIR}. Run a `cargo xwin build` once, "
    "or pass -DXWIN_CACHE_DIR=<dir> (or set XWIN_CACHE_DIR / CARGO_HOME).")
endif()

set(_xwin_arch x86_64)

find_program(CLANG_CL_EXECUTABLE clang-cl REQUIRED)
find_program(LLD_LINK_EXECUTABLE lld-link REQUIRED)
find_program(LLVM_LIB_EXECUTABLE llvm-lib REQUIRED)
find_program(LLVM_RC_EXECUTABLE llvm-rc REQUIRED)
# For install(RUNTIME_DEPENDENCIES) / file(GET_RUNTIME_DEPENDENCIES) on PE images.
find_program(LLVM_OBJDUMP_EXECUTABLE NAMES llvm-objdump objdump)
if(LLVM_OBJDUMP_EXECUTABLE)
  set(CMAKE_OBJDUMP "${LLVM_OBJDUMP_EXECUTABLE}" CACHE FILEPATH "" FORCE)
endif()

set(CMAKE_C_COMPILER "${CLANG_CL_EXECUTABLE}")
set(CMAKE_CXX_COMPILER "${CLANG_CL_EXECUTABLE}")
set(CMAKE_C_COMPILER_TARGET ${_xwin_arch}-pc-windows-msvc)
set(CMAKE_CXX_COMPILER_TARGET ${_xwin_arch}-pc-windows-msvc)
set(CMAKE_RC_COMPILER "${LLVM_RC_EXECUTABLE}")
set(CMAKE_AR "${LLVM_LIB_EXECUTABLE}")

# Pin the target, use lld-link, and add the MSVC headers as /imsvc system
# includes (the same set cargo-xwin uses).
set(_xwin_inc
  "/imsvc${XWIN_CACHE_DIR}/crt/include \
/imsvc${XWIN_CACHE_DIR}/sdk/include/ucrt \
/imsvc${XWIN_CACHE_DIR}/sdk/include/um \
/imsvc${XWIN_CACHE_DIR}/sdk/include/shared \
/imsvc${XWIN_CACHE_DIR}/sdk/include/winrt")
# WIN32_LEAN_AND_MEAN: drop winsock1 from windows.h (OM uses winsock2 directly).
set(_xwin_flags "--target=${_xwin_arch}-pc-windows-msvc -fuse-ld=lld-link -Wno-unused-command-line-argument /DWIN32_LEAN_AND_MEAN ${_xwin_inc}")
set(CMAKE_C_FLAGS_INIT "${_xwin_flags}")
set(CMAKE_CXX_FLAGS_INIT "${_xwin_flags}")

# llvm-rc needs the SDK headers via its own -I (e.g. winver.h). /C 1252 sets the
# input codepage so Latin-1 bytes in .rc files (e.g. xerces's © in LegalCopyright)
# are accepted; harmless for ASCII .rc.
set(CMAKE_RC_FLAGS_INIT
  "/C 1252 \
-I ${XWIN_CACHE_DIR}/sdk/include/um \
-I ${XWIN_CACHE_DIR}/sdk/include/shared \
-I ${XWIN_CACHE_DIR}/sdk/include/ucrt \
-I ${XWIN_CACHE_DIR}/crt/include")

set(_xwin_libpath
  "-libpath:${XWIN_CACHE_DIR}/crt/lib/${_xwin_arch} \
-libpath:${XWIN_CACHE_DIR}/sdk/lib/um/${_xwin_arch} \
-libpath:${XWIN_CACHE_DIR}/sdk/lib/ucrt/${_xwin_arch}")
set(CMAKE_EXE_LINKER_FLAGS_INIT "${_xwin_libpath}")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${_xwin_libpath}")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "${_xwin_libpath}")

# Programs from the host; libs/headers/packages from BOTH sysroot and prefixes
# (vcpkg installs under CMAKE_PREFIX_PATH, not the sysroot).
set(CMAKE_FIND_ROOT_PATH "${XWIN_CACHE_DIR}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

# Boost.Context (vcpkg dep of boost-asio): use the Windows-fibers backend, which
# is pure C++ — no assembly. The default fcontext backend assembles a MASM
# trampoline via ml64, and llvm-ml64 rejects Boost's MASM (EXPORT / .seh_); its
# CMake build can't select the clang-gas .S variant that would assemble cleanly.
set(BOOST_CONTEXT_IMPLEMENTATION winfib CACHE STRING "" FORCE)

# Qt's WrapVulkanHeaders (a Qt6::Gui dep) finds the host /usr/include/vulkan and
# leaks the whole host /usr/include as a system include for the Windows target,
# pulling glibc headers. OM uses no Vulkan, so disable the find.
set(CMAKE_DISABLE_FIND_PACKAGE_Vulkan ON CACHE BOOL "" FORCE)
