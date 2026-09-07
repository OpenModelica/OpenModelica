# Build the Rust (mmtorust) omc port instead of the bootstrapped C omc.
#
# Enabled with -DOM_OMC_ENABLE_RUST=ON. The chain, all native Rust (no bomc/omc,
# no system omc, no shell scripts):
#
#   1. cargo build the build *tools* (mmtorust, susan) -- always --release, since
#      they run during the build and release is dramatically faster.
#   2. `mmtorust susan` transpiles the Susan-subset crates; cargo builds `susan`.
#   3. `susan` compiles every *.tpl -> *.mo (the omc_add_template_target rules,
#      which use ${OMC_EXE}; in Rust mode ${OMC_EXE} is the susan binary).
#   4. `mmtorust` (full) transpiles all of compilerSources.txt -> crate .rs.
#   5. cargo builds the omc artifacts (openmodelica, libopenmodelica_compiler)
#      with a selectable profile (RUST_OMC_PROFILE, default "debug").
#
# mmtorust writes the generated *.rs into the crate src/ dirs and cargo builds
# there, so each build gets its OWN copy (RUST_OMC_DIR) mirrored from the source
# (RUST_OMC_SRC_DIR) — a shared in-source tree let concurrent builds clobber each
# other's generated sources. Hand-written and generated *.rs share src/ dirs, so
# the whole hand-written set (.cmake/rust_src_files.txt) is copied.

find_program(CARGO_EXECUTABLE cargo REQUIRED)

set(RUST_OMC_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/OpenModelica.rs
    CACHE PATH "Canonical Rust omc source tree (mirrored into the per-build copy).")
# sccache hashes CARGO_MANIFEST_DIR into the Rust cache key, so a per-checkout
# working copy makes every crate a guaranteed miss; CI pins this (.CI/common.groovy
# rustWorkDir()).
set(RUST_OMC_WORK_DIR ${CMAKE_CURRENT_BINARY_DIR}
    CACHE PATH "Parent directory of the per-build Rust working copy (rust-src).")
# The working copy reproduces the OMCompiler/ tree shape, because the two cargo
# workspaces path-reference each other across it: the compiler's crates name
# ../../SimulationRuntime/rust/*, the runtime's name ../../Compiler/OpenModelica.rs/*,
# and openmodelica_wasi include_str!s ../../../FrontEnd/*.mo.
# Not cached: a normal set() shadows a stale cache from before this was per-build,
# so reconfiguring an existing build dir picks up the new path.
set(RUST_OMC_TREE ${RUST_OMC_WORK_DIR}/rust-src)
set(RUST_OMC_DIR ${RUST_OMC_TREE}/Compiler/OpenModelica.rs)
set(RUST_SRC_MANIFEST ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/rust_src_files.txt)
# The simulation runtime is a workspace of its own (no generated sources); it is
# mirrored only so the compiler workspace's path dependencies resolve in here.
set(RUST_SIMRT_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../SimulationRuntime/rust)
set(RUST_SIMRT_DIR ${RUST_OMC_TREE}/SimulationRuntime/rust)

# Mirror now so the configure-time reads below (.gitignore, susanSources.txt) see
# a populated copy; the rust_src_sync target re-mirrors before each build step.
set(_rust_src_sync_cmd ${CMAKE_COMMAND}
    -DSRC=${RUST_OMC_SRC_DIR} -DDST=${RUST_OMC_DIR} -DMANIFEST=${RUST_SRC_MANIFEST} -DBUILTINS=ON
    -P ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/rust_src_sync.cmake)
set(_rust_simrt_sync_cmd ${CMAKE_COMMAND}
    -DSRC=${RUST_SIMRT_SRC_DIR} -DDST=${RUST_SIMRT_DIR}
    -DMANIFEST=${RUST_SIMRT_SRC_DIR}/.cmake/rust_src_files.txt
    -P ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/rust_src_sync.cmake)
foreach(_cmd _rust_src_sync_cmd _rust_simrt_sync_cmd)
  execute_process(COMMAND ${${_cmd}} RESULT_VARIABLE _rust_src_sync_rc)
  if(_rust_src_sync_rc)
    message(FATAL_ERROR "Initial Rust source mirror failed (${_cmd}).")
  endif()
endforeach()
add_custom_target(rust_src_sync
  COMMAND ${_rust_src_sync_cmd}
  COMMAND ${_rust_simrt_sync_cmd}
  COMMENT "Rust: syncing hand-written sources -> per-build working copy"
  VERBATIM)

# Bootstrap placeholder src/lib.rs for the crates whose lib.rs is emitted by the
# mmtorust transpile (and therefore .gitignore'd). On a clean checkout these
# files don't exist yet, but every `cargo` invocation loads the whole workspace,
# and a member with a Cargo.toml but no src/lib.rs (or main.rs) aborts the load
# with "no targets specified in the manifest". That kills the very first cargo
# build (mmtorust / scripting_api_gen / susan, all run *before* the full codegen)
# before mmtorust ever runs to emit them. Drop an empty placeholder so the
# manifest has a target; the transpile overwrites it (the susan-subset crates at
# `mmtorust susan`, the rest at the full transpile). Only write it when missing,
# so a real generated lib.rs is never clobbered (mtimes / codegen DEPENDS stay
# put). The set IS the `*/src/lib.rs` entries of OpenModelica.rs/.gitignore —
# read them straight from there so this never drifts from the ignore list.
file(STRINGS ${RUST_OMC_DIR}/.gitignore _rust_gitignore_lines)
foreach(_line ${_rust_gitignore_lines})
  if(_line MATCHES "/src/lib\\.rs$" AND NOT _line MATCHES "^#")
    if(NOT EXISTS ${RUST_OMC_DIR}/${_line})
      file(WRITE ${RUST_OMC_DIR}/${_line}
           "// Bootstrap placeholder; overwritten by the mmtorust transpile. See rust_omc.cmake.\n")
    endif()
  endif()
endforeach()

# CI builds: one switch that flips the defaults to a clean, reproducible build —
# the release profile and cargo incremental compilation OFF (incremental
# artifacts are pure overhead for a from-scratch CI build and bloat the cache).
# It only changes the *defaults* of RUST_OMC_PROFILE / RUST_OMC_INCREMENTAL, so
# either can still be overridden explicitly on the command line.
option(RUST_OMC_CI "CI build of the Rust omc: default to the release profile with cargo incremental compilation disabled." OFF)
if(RUST_OMC_CI)
  set(_rust_omc_profile_default "release")
  set(_rust_omc_incremental_default OFF)
else()
  set(_rust_omc_profile_default "debug")
  set(_rust_omc_incremental_default ON)
endif()

# The omc artifacts (the deliverables) honour this profile; default debug.
# The build tools (mmtorust, susan) are always release regardless.
set(RUST_OMC_PROFILE "${_rust_omc_profile_default}"
    CACHE STRING "Cargo profile for the Rust omc artifacts: debug or release.")
if(RUST_OMC_PROFILE STREQUAL "release")
  set(RUST_OMC_PROFILE_FLAG "--release")
  set(RUST_OMC_TARGET_SUBDIR "release")
else()
  set(RUST_OMC_PROFILE_FLAG "")
  set(RUST_OMC_TARGET_SUBDIR "debug")
endif()

# ---------------------------------------------------------------------------
# Cross-compile the omc *artifacts* (cdylib + launcher + GUI clients) for
# RUST_OMC_TARGET via `cargo xwin`; the build tools stay on/for the host. Empty
# = native build. Only *-windows-msvc is wired (cargo-xwin targets MSVC); the
# artifacts then land in target/<triple>/<profile>/ with .exe/.dll names.
set(RUST_OMC_TARGET "" CACHE STRING
    "Rust target triple to cross-compile the omc artifacts for via cargo-xwin (e.g. x86_64-pc-windows-msvc). Empty = native host build.")
if(RUST_OMC_TARGET)
  if(NOT RUST_OMC_TARGET MATCHES "windows-msvc$")
    message(FATAL_ERROR "RUST_OMC_TARGET=${RUST_OMC_TARGET} is unsupported; only *-windows-msvc triples are wired (cargo-xwin).")
  endif()
  # The dev profile selects the cranelift rustc backend, which cannot target
  # windows-msvc; a cross build must use release (LLVM backend).
  if(NOT RUST_OMC_PROFILE STREQUAL "release")
    message(FATAL_ERROR "Cross-compiling (RUST_OMC_TARGET set) requires -DRUST_OMC_PROFILE=release (the dev profile's cranelift backend cannot target ${RUST_OMC_TARGET}).")
  endif()
  set(RUST_OMC_ARTIFACT_SUBDIR ${RUST_OMC_TARGET}/${RUST_OMC_TARGET_SUBDIR})
  set(RUST_OMC_EXE_SUFFIX ".exe")
  set(RUST_OMC_CDYLIB_NAME "OpenModelicaCompiler.dll")
else()
  set(RUST_OMC_ARTIFACT_SUBDIR ${RUST_OMC_TARGET_SUBDIR})
  set(RUST_OMC_EXE_SUFFIX "")
  set(RUST_OMC_CDYLIB_NAME "libOpenModelicaCompiler.so")
endif()

# Cargo incremental compilation: ON for fast local iteration, OFF for CI (set by
# RUST_OMC_CI). Honoured by every cargo invocation via CARGO_ENV below.
option(RUST_OMC_INCREMENTAL "Use cargo incremental compilation for the Rust omc build (OFF for CI)." ${_rust_omc_incremental_default})

# Emit cargo's --timings HTML report for the omc artifact builds (cdylib +
# launcher) to <target-dir>/cargo-timings/. CI archives it; off by default.
option(RUST_OMC_TIMINGS "Emit cargo --timings HTML reports for the omc artifact builds." OFF)
if(RUST_OMC_TIMINGS)
  # Bare --timings (defaults to the HTML report); this cargo rejects --timings=html.
  set(RUST_OMC_TIMINGS_FLAG --timings)
else()
  set(RUST_OMC_TIMINGS_FLAG "")
endif()

# Compile the OMEdit C-ABI (the `scripting_api` cdylib feature) independently of
# whether the Qt GUI clients are built in THIS configuration. Defaults to
# OM_ENABLE_GUI_CLIENTS (so every existing build is unchanged), but a split CI
# can force it ON: stage 1 builds the Rust omc with the GUI subdirs OFF yet still
# emits a cdylib carrying the OMEdit symbols, which stage 2 links the GUI against
# (see RUST_OMC_PREBUILT_CDYLIB below).
option(RUST_OMC_SCRIPTING_API
  "Compile the OMEdit C-ABI (scripting_api) into the cdylib even when the GUI clients are not built in this configuration."
  ${OM_ENABLE_GUI_CLIENTS})

# Prebuilt-cdylib hand-off (mirrors RUST_OMC_WASM_RUNTIME below): point a GUI-only
# build at an already-built libOpenModelicaCompiler.so + the generated Qt API
# sources from an earlier stage, so configuring with the GUI clients ON does NOT
# run cargo or the codegen at all (Compiler/CMakeLists.txt takes the prebuilt
# branch). Empty = build the cdylib normally via cargo.
set(RUST_OMC_PREBUILT_CDYLIB "" CACHE FILEPATH
    "Prebuilt libOpenModelicaCompiler.so to link the GUI against (empty = build it via cargo). Set in the GUI-only CI stage to skip the Rust build entirely.")
set(RUST_OMC_PREBUILT_SCRIPTING_API_QT_DIR "" CACHE PATH
    "Directory holding the prebuilt OpenModelicaScriptingAPIQt.{cpp,h} (used with RUST_OMC_PREBUILT_CDYLIB).")

option(RUST_OMC_PREBUILT_GENERATED_SRC
  "Assume the mmtorust-generated *.rs are already present (e.g. unstashed from an earlier CI stage) and skip the transpile."
  OFF)

# Each client is a separate cargo build resolving the workspace to a different
# feature set than the cdylib, sharing one target directory: cargo cannot reuse
# the fingerprints, so every compiler crate is rebuilt per client, every build.
# The browser OMShell pages come from the wasm target and are not affected.
option(RUST_OMC_OMSHELL_CLIENTS
  "Build the desktop egui + dioxus/Blitz OMShell clients. Off by default: each is a separate cargo feature resolution and rebuilds every compiler crate."
  OFF)

# cargo target/ lives in the build tree, not the source crate tree.
set(RUST_OMC_TARGET_DIR ${CMAKE_CURRENT_BINARY_DIR}/rust-target
    CACHE PATH "Directory for cargo's target/ output of the Rust omc build.")
set(RUST_TARGET_DIR ${RUST_OMC_TARGET_DIR})
# Published so the sibling libSimulationRuntimeRust build (SimulationRuntime/rust)
# can share this working copy and target directory instead of building the same
# crates a second time from the canonical tree.
set_property(GLOBAL PROPERTY OMC_RUST_WORKSPACE_DIR ${RUST_OMC_DIR})
set_property(GLOBAL PROPERTY OMC_RUST_TARGET_DIR ${RUST_TARGET_DIR})
# Env prefix for every cargo invocation. When incremental compilation is off we
# export CARGO_INCREMENTAL=0, which covers all profiles (including the
# always-debug `cargo test` build) without editing per-profile Cargo.toml keys.
set(CARGO_ENV ${CMAKE_COMMAND} -E env)
if(NOT RUST_OMC_INCREMENTAL)
  list(APPEND CARGO_ENV CARGO_INCREMENTAL=0)
endif()

# Linker + front-end parallelism for the native cargo builds, applied via
# CARGO_TARGET_<host-triple>_RUSTFLAGS so they are scoped to the host (the wasm32
# cross-build's .wasm is never touched).
#
#   * mold (RUST_OMC_MOLD, default ON): link with mold when it is found on PATH.
#     Set OFF if only an old mold is available: mold < 1.7 lacks
#     --export-dynamic-symbol, which the omc launcher needs to re-export
#     omc_Error_getCurrentComponent. The Jenkins image installs a current mold;
#     when OFF the fallback is the toolchain default (rust's bundled lld, itself
#     a fast linker that supports the flag).
#   * RUST_OMC_THREADS (>0): pass nightly rustc's -Zthreads=N to parallelise the
#     compiler front-end, which dominates the build of the huge generated crates
#     (their dependency chain is near-linear, so the front-ends sit on the serial
#     critical path). Off by default; needs the nightly toolchain.
option(RUST_OMC_MOLD "Link the native cargo builds with mold when found on PATH." ON)
set(RUST_OMC_THREADS "0" CACHE STRING
    "If >0, pass rustc -Zthreads=N to parallelise the compiler front-end (nightly only).")
set(_rust_host_rustflags "")
if(RUST_OMC_MOLD)
  find_program(MOLD_EXECUTABLE mold)
  if(MOLD_EXECUTABLE)
    list(APPEND _rust_host_rustflags "-Clink-arg=-fuse-ld=mold")
  endif()
endif()
if(RUST_OMC_THREADS GREATER 0)
  list(APPEND _rust_host_rustflags "-Zthreads=${RUST_OMC_THREADS}")
endif()
if(_rust_host_rustflags)
  execute_process(COMMAND ${CARGO_EXECUTABLE} -vV
                  OUTPUT_VARIABLE _rust_cargo_vv OUTPUT_STRIP_TRAILING_WHITESPACE)
  if(_rust_cargo_vv MATCHES "host: ([A-Za-z0-9_-]+)")
    string(TOUPPER "${CMAKE_MATCH_1}" _rust_host_env)
    string(REPLACE "-" "_" _rust_host_env "${_rust_host_env}")
    string(REPLACE ";" " " _rust_host_rustflags "${_rust_host_rustflags}")
    list(APPEND CARGO_ENV "CARGO_TARGET_${_rust_host_env}_RUSTFLAGS=${_rust_host_rustflags}")
  endif()
endif()
# Forward the configured generated-code link flags to the cargo build; Autoconf.rs
# reads them via option_env! (with a cfg!-based fallback). Single source of truth
# shared with the C runtime build (only platform booleans, so it's safe here).
include(${CMAKE_CURRENT_SOURCE_DIR}/runtime/rt_ldflags_generated_code.cmake)

# ---------------------------------------------------------------------------
# WASI toolchain discovery (shared by wasi-libc PIC sysroot and sundials wasm).
# ---------------------------------------------------------------------------
find_program(LLVM_AR_EXECUTABLE llvm-ar)
find_program(LLVM_RANLIB_EXECUTABLE llvm-ranlib)
if(NOT LLVM_AR_EXECUTABLE OR NOT LLVM_RANLIB_EXECUTABLE)
  execute_process(COMMAND clang -dumpversion OUTPUT_VARIABLE _clang_ver
                  OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
  if(_clang_ver MATCHES "^([0-9]+)")
    set(_clang_major "${CMAKE_MATCH_1}")
    find_program(LLVM_AR_EXECUTABLE llvm-ar-${_clang_major})
    find_program(LLVM_RANLIB_EXECUTABLE llvm-ranlib-${_clang_major})
  endif()
endif()

find_program(_omc_wasi_clang clang)
if(_omc_wasi_clang)
  execute_process(
    COMMAND ${_omc_wasi_clang} -print-resource-dir
    OUTPUT_VARIABLE _clang_res_dir OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
  if(_clang_res_dir)
    set(_wasi_builtins ${_clang_res_dir}/lib/wasi/libclang_rt.builtins-wasm32.a)
  endif()
endif()

# PIC wasi-libc sysroot (for external "C" in wasm FMUs).
#
# Built by CMake using wasi-libc's own CMakeLists.txt with BUILD_SHARED=ON
# so it produces a -fPIC libc.so (Debian's is non-PIC).
# ---------------------------------------------------------------------------
if(NOT LLVM_AR_EXECUTABLE OR NOT LLVM_RANLIB_EXECUTABLE)
  message(FATAL_ERROR "llvm-ar/llvm-ranlib not found; required to build the wasi-libc PIC sysroot.")
endif()
if(NOT _wasi_builtins OR NOT EXISTS ${_wasi_builtins})
  message(FATAL_ERROR "libclang_rt.builtins-wasm32.a not found (install libclang-rt-*-dev-wasm32).")
endif()

set(RUST_WASI_PIC_SYSROOT ${CMAKE_BINARY_DIR}/rust-wasi-pic-sysroot
    CACHE PATH "Output directory for the PIC wasi-libc sysroot.")

# Write the wasm32-wasip1 toolchain file for CMake to use when cross-compiling.
set(_wasi_toolchain ${CMAKE_CURRENT_BINARY_DIR}/wasi-toolchain.cmake)
file(WRITE ${_wasi_toolchain}
  "set(CMAKE_SYSTEM_NAME WASI)\n"
  "set(CMAKE_SYSTEM_PROCESSOR wasm32)\n"
  "set(CMAKE_C_COMPILER clang)\n"
  "set(CMAKE_C_COMPILER_TARGET wasm32-wasip1)\n"
  "set(CMAKE_SYSROOT ${RUST_WASI_PIC_SYSROOT})\n"
  "set(CMAKE_AR ${LLVM_AR_EXECUTABLE})\n"
  "set(CMAKE_RANLIB ${LLVM_RANLIB_EXECUTABLE})\n"
  "set(CMAKE_C_FLAGS_INIT \"-O2\")\n"
  "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)\n"
  "set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)\n")
set(_wasi_libc_src ${CMAKE_BINARY_DIR}/downloads/wasi-libc/wasi-libc-wasi-sdk-32)
if(NOT EXISTS ${_wasi_libc_src}/CMakeLists.txt)
  set(_wasi_tgz ${CMAKE_BINARY_DIR}/downloads/wasi-libc-wasi-sdk-32.tar.gz)
  message(STATUS "Downloading wasi-libc (wasi-sdk-32) source…")
  file(DOWNLOAD
       https://github.com/WebAssembly/wasi-libc/archive/refs/tags/wasi-sdk-32.tar.gz
       ${_wasi_tgz}
       EXPECTED_HASH SHA256=ea9827495c0f35bca3b3d0a953e854cac112c43bea3196b5a4f7f8fc4704b9a4
       TLS_VERIFY ON STATUS _wasi_dl)
  list(GET _wasi_dl 0 _wasi_dl_code)
  if(NOT _wasi_dl_code EQUAL 0)
    file(REMOVE ${_wasi_tgz})
    message(FATAL_ERROR "Failed to download wasi-libc source (${_wasi_dl})")
  else()
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/downloads/wasi-libc)
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${_wasi_tgz}
                    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/downloads/wasi-libc
                    RESULT_VARIABLE _wasi_untar)
    if(NOT _wasi_untar EQUAL 0)
      message(FATAL_ERROR "Failed to unpack wasi-libc source")
    endif()
  endif()
endif()

# Build wasi-libc PIC sysroot via ExternalProject (honours jobserver, proper progress).
include(ExternalProject)
set(_wasi_libc_ep_build ${CMAKE_BINARY_DIR}/rust-wasi-libc-wasm-ep-build)
ExternalProject_Add(rust_wasi_pic_sysroot
  SOURCE_DIR ${_wasi_libc_src}
  BINARY_DIR ${_wasi_libc_ep_build}
  CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${_wasi_toolchain}
    -DBUILD_SHARED=ON -DBUILD_TESTS=OFF
    -DCMAKE_LINK_DEPENDS_USE_LINKER=OFF
    -DBUILTINS_LIB=${_wasi_builtins}
  BUILD_ALWAYS ON
  BUILD_COMMAND ${CMAKE_COMMAND} --build ${_wasi_libc_ep_build} --parallel
  INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${_wasi_libc_ep_build}/sysroot ${RUST_WASI_PIC_SYSROOT}
  EXCLUDE_FROM_ALL ON)

# ---------------------------------------------------------------------------
# SUNDIALS/KLU/UMFPACK/Lis wasm cross-compile.
#
# Separate from the native C runtime build (3rdParty/CMakeLists.txt). Uses the
# same sources but a wasm32-wasip1 toolchain and a distinct build directory.
# Produces static archives linked into the wasm-jit runtimes (FMI/web), which is
# what makes `-ls`/`-lss`/`-idaLS` name the same solvers the C runtime does.
# ---------------------------------------------------------------------------
option(RUST_OMC_ENABLE_SUNDIALS "Build the 3rd-party solver archives (SUNDIALS/KLU/UMFPACK/Lis) for wasm32-wasip1, as used by the wasm-jit runtime." ON)

if(RUST_OMC_ENABLE_SUNDIALS)
  set(_sundials_sources ${CMAKE_CURRENT_SOURCE_DIR}/../3rdParty/sundials)
  set(_suitesparse_sources ${CMAKE_CURRENT_SOURCE_DIR}/../3rdParty/SuiteSparse)

  # SuiteSparse toolchain: base wasi toolchain + include dirs for KLU headers.
  # CMAKE_C_FLAGS_INIT is a STRING (not list) so no semicolon issues.
  #
  # `-fPIC`: one archive set serves both users. wasm-ld relaxes the GOT/`__memory_base`
  # relocations away in a non-PIC link, so the wasip1 runtime that links these
  # statically gets a byte-identical module -- while an FMU's `--experimental-pic
  # --shared` SUNDIALS side module can only be linked from PIC objects at all.
  set(_sundials_cflags "-O2 -fPIC -I${_suitesparse_sources}/AMD/Include -I${_suitesparse_sources}/COLAMD/Include -I${_suitesparse_sources}/BTF/Include -I${_suitesparse_sources}/SuiteSparse_config")
  # UMFPACK adds its own headers and `NBLAS`, its no-BLAS build, there being no
  # BLAS for wasm. Passed as CMAKE_C_FLAGS, not through the toolchain's
  # CMAKE_C_FLAGS_INIT, which an already-configured build directory ignores.
  set(_suitesparse_cflags "${_sundials_cflags} -DNBLAS -I${_suitesparse_sources}/UMFPACK/Include")
  set(_sundials_toolchain ${CMAKE_CURRENT_BINARY_DIR}/sundials-wasi-toolchain.cmake)
  file(WRITE ${_sundials_toolchain}
    "set(CMAKE_SYSTEM_NAME WASI)\n"
    "set(CMAKE_SYSTEM_PROCESSOR wasm32)\n"
    "set(CMAKE_C_COMPILER clang)\n"
    "set(CMAKE_C_COMPILER_TARGET wasm32-wasip1)\n"
    "set(CMAKE_SYSROOT ${RUST_WASI_PIC_SYSROOT})\n"
    "set(CMAKE_AR ${LLVM_AR_EXECUTABLE})\n"
    "set(CMAKE_RANLIB ${LLVM_RANLIB_EXECUTABLE})\n"
    "set(CMAKE_C_FLAGS_INIT \"${_sundials_cflags}\")\n"
    "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)\n"
    "set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)\n")

  # SuiteSparse wasm via ExternalProject.
  set(_suitesparse_ep_build ${CMAKE_BINARY_DIR}/rust-suitesparse-wasm-ep-build)
  ExternalProject_Add(rust_suitesparse_wasm
    SOURCE_DIR ${_suitesparse_sources}
    BINARY_DIR ${_suitesparse_ep_build}
    LIST_SEPARATOR |
    CMAKE_ARGS
      -DCMAKE_TOOLCHAIN_FILE=${_sundials_toolchain}
      -DCMAKE_C_FLAGS=${_suitesparse_cflags}
      -DBUILD_SHARED_LIBS=OFF
      -DSUITESPARSE_ENABLE_PROJECTS=suitesparse_config|amd|colamd|btf|klu|umfpack
      -DSUITESPARSE_USE_FORTRAN=OFF
      -DSUITESPARSE_USE_OPENMP=OFF
      -DSUITESPARSE_USE_CUDA=OFF
      -DSUITESPARSE_DEMOS=OFF
      -DSUITESPARSE_USE_STRICT=OFF
      -DKLU_USE_CHOLMOD=OFF
      -DUMFPACK_USE_CHOLMOD=OFF
      # An empty BLAS_LIBRARIES takes SuiteSparseBLAS's "user supplied" path
      # instead of find_package(BLAS); BLA_VENDOR only picks name-mangling defines.
      -DBLAS_LIBRARIES=
      -DBLA_VENDOR=Generic
    BUILD_COMMAND ${CMAKE_COMMAND} --build ${_suitesparse_ep_build} --parallel
      --target KLU_static UMFPACK_static AMD_static COLAMD_static BTF_static SuiteSparseConfig_static
    INSTALL_COMMAND ""
    BUILD_ALWAYS ON
    EXCLUDE_FROM_ALL ON)
  add_dependencies(rust_suitesparse_wasm rust_wasi_pic_sysroot)

  # -------------------------------------------------------------------------
  # Lis wasm (`-ls lis` / `-lss lis`). 3rdParty/lis-1.4.12 has no standalone
  # CMake entry point: its top-level CMakeLists needs the C-runtime build's
  # helper modules already included, and `configure_file`s the generated
  # `lis_config.h` back into the *source* tree, where the native build's copy
  # (8-byte long, x87 FPU) sits. So run upstream's own recipe from a project of
  # ours, with the header in the build tree ahead of the source include dir.
  # -------------------------------------------------------------------------
  set(_lis_sources ${CMAKE_CURRENT_SOURCE_DIR}/../3rdParty/lis-1.4.12)
  set(_lis_ep_dir ${CMAKE_BINARY_DIR}/rust-lis-wasm)
  set(_lis_ep_build ${CMAKE_BINARY_DIR}/rust-lis-wasm-ep-build)
  file(WRITE ${_lis_ep_dir}/CMakeLists.txt.tmp
"# Generated by OMCompiler/Compiler/.cmake/rust_omc.cmake - do not edit.
cmake_minimum_required(VERSION 3.14)
project(LisWasm C)
include(CheckTypeSize)
include(CheckIncludeFile)

# The checks lis-1.4.12/CMakeLists.txt runs, answered for wasm32-wasip1.
set(HAS_X87_FPU FALSE)
check_type_size(double SIZEOF_DOUBLE)
check_type_size(float SIZEOF_FLOAT)
check_type_size(int SIZEOF_INT)
check_type_size(long SIZEOF_LONG)
check_type_size(\"long double\" SIZEOF_LONG_DOUBLE)
check_type_size(\"long long\" SIZEOF_LONG_LONG)
check_type_size(size_t SIZEOF_SIZE_T)
set(SIZEOF_VOID_P \${CMAKE_SIZEOF_VOID_P})
set(STDC_HEADERS 1)
foreach(_h dlfcn.h inttypes.h malloc.h memory.h stdint.h stdlib.h strings.h
           string.h sys/stat.h sys/time.h sys/types.h unistd.h sys/mount.h)
  string(TOUPPER \"HAVE_\${_h}\" _def)
  string(REGEX REPLACE \"[./]\" \"_\" _def \"\${_def}\")
  check_include_file(\${_h} \${_def})
endforeach()
configure_file(${_lis_sources}/include/lis_config.h.in.cmake
               \${CMAKE_CURRENT_BINARY_DIR}/include/lis_config.h)

foreach(_d matrix vector matvec precon solver esolver system precision)
  file(GLOB _s ${_lis_sources}/src/\${_d}/*.c)
  list(APPEND LIS_SOURCES \${_s})
endforeach()
add_library(lis STATIC \${LIS_SOURCES})
target_compile_definitions(lis PRIVATE HAVE_CONFIG_H)
target_include_directories(lis PRIVATE
  \${CMAKE_CURRENT_BINARY_DIR}/include ${_lis_sources}/include)
")
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different
                  ${_lis_ep_dir}/CMakeLists.txt.tmp ${_lis_ep_dir}/CMakeLists.txt)
  ExternalProject_Add(rust_lis_wasm
    SOURCE_DIR ${_lis_ep_dir}
    BINARY_DIR ${_lis_ep_build}
    CMAKE_ARGS
      -DCMAKE_TOOLCHAIN_FILE=${_sundials_toolchain}
      -DCMAKE_C_FLAGS=${_sundials_cflags}
      -DBUILD_SHARED_LIBS=OFF
    BUILD_COMMAND ${CMAKE_COMMAND} --build ${_lis_ep_build} --parallel
    INSTALL_COMMAND ""
    BUILD_ALWAYS ON
    EXCLUDE_FROM_ALL ON)
  add_dependencies(rust_lis_wasm rust_wasi_pic_sysroot)

  # -------------------------------------------------------------------------
  # PRIMME wasm (`-lv=LOG_NLS_SVD` with `-svdCount`, the partial SVD of a
  # nonlinear system's Jacobian). 3rdParty/primme-3.2.3's own CMakeLists wants a
  # BLAS/LAPACK to link against, which wasm has none of; the archive needs none,
  # so build the sources directly. Its BLAS/LAPACK calls resolve against
  # `openmodelica_lapack`'s Fortran ABI when the runtime links it.
  #
  # `-ffunction-sections` matters: `--gc-sections` then drops every precision but
  # the double-real one, which is what keeps the undefined set down to the dozen
  # entry points that crate exports. `__unix__` picks `wtime.c`'s POSIX timer
  # (the alternative is `windows.h`), and the process clocks it includes are
  # emulated.
  # -------------------------------------------------------------------------
  set(_primme_sources ${CMAKE_CURRENT_SOURCE_DIR}/../3rdParty/primme-3.2.3)
  set(_primme_ep_dir ${CMAKE_BINARY_DIR}/rust-primme-wasm)
  set(_primme_ep_build ${CMAKE_BINARY_DIR}/rust-primme-wasm-ep-build)
  file(WRITE ${_primme_ep_dir}/CMakeLists.txt.tmp
"# Generated by OMCompiler/Compiler/.cmake/rust_omc.cmake - do not edit.
cmake_minimum_required(VERSION 3.14)
project(PrimmeWasm C)
file(GLOB PRIMME_SOURCES ${_primme_sources}/src/eigs/*.c ${_primme_sources}/src/linalg/*.c
                         ${_primme_sources}/src/svds/*.c)
# The runtime's entry point into it, kept in C so `primme_svds_params` is never
# described twice.
list(APPEND PRIMME_SOURCES ${RUST_SIMRT_DIR}/openmodelica_nls/src/primme_svds.c)
add_library(primme STATIC \${PRIMME_SOURCES})
target_compile_definitions(primme PRIVATE
  PRIMME_WITHOUT_FLOAT F77UNDERSCORE __unix__ _WASI_EMULATED_PROCESS_CLOCKS)
target_compile_options(primme PRIVATE -std=c99 -ffunction-sections -fdata-sections)
target_include_directories(primme PRIVATE
  ${_primme_sources}/include ${_primme_sources}/src/include)
")
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different
                  ${_primme_ep_dir}/CMakeLists.txt.tmp ${_primme_ep_dir}/CMakeLists.txt)
  ExternalProject_Add(rust_primme_wasm
    SOURCE_DIR ${_primme_ep_dir}
    BINARY_DIR ${_primme_ep_build}
    CMAKE_ARGS
      -DCMAKE_TOOLCHAIN_FILE=${_sundials_toolchain}
      -DCMAKE_C_FLAGS=${_sundials_cflags}
      -DBUILD_SHARED_LIBS=OFF
    BUILD_COMMAND ${CMAKE_COMMAND} --build ${_primme_ep_build} --parallel
    INSTALL_COMMAND ""
    BUILD_ALWAYS ON
    EXCLUDE_FROM_ALL ON)
  add_dependencies(rust_primme_wasm rust_wasi_pic_sysroot rust_src_sync)

  # SUNDIALS wasm via ExternalProject.
  set(_sundials_ep_build ${CMAKE_BINARY_DIR}/rust-sundials-wasm-ep-build)
  set(RUST_SUNDIALS_WASM_DIR ${CMAKE_BINARY_DIR}/rust-sundials-wasm
      CACHE PATH "Output directory for the SUNDIALS/KLU wasm32-wasip1 archives.")
  ExternalProject_Add(rust_sundials_wasm
    SOURCE_DIR ${_sundials_sources}
    BINARY_DIR ${_sundials_ep_build}
    CMAKE_ARGS
      -DCMAKE_TOOLCHAIN_FILE=${_sundials_toolchain}
      -DCMAKE_C_FLAGS=${_sundials_cflags}
      # Keep in sync with 3rdParty/CMakeLists.txt.
      -DBUILD_STATIC_LIBS=ON
      -DBUILD_SHARED_LIBS=OFF
      -DSUNDIALS_ENABLE_LAPACK=OFF
      -DSUNDIALS_ENABLE_C_EXAMPLES=OFF
      -DSUNDIALS_ENABLE_CXX_EXAMPLES=OFF
      -DSUNDIALS_ENABLE_EXAMPLES_INSTALL=OFF
      -DSUNDIALS_ENABLE_BENCHMARKS=OFF
      -DSUNDIALS_TEST_ENABLE_UNIT_TESTS=OFF
      -DSUNDIALS_ENABLE_ERROR_CHECKS=OFF
      -DSUNDIALS_ENABLE_FORTRAN=OFF
      -DSUNDIALS_ENABLE_KLU=ON
      # The KLU compatibility checks try_compile() against the archives below.
      # The toolchain builds try_compile targets as static libraries, so nothing
      # is actually linked and the check cannot tell us anything.
      -DSUNDIALS_ENABLE_KLU_CHECKS=OFF
      -DSUNDIALS_INDEX_SIZE=32
      # SundialsPOSIXTimers.cmake probes the timers by generating a *sub-project*
      # and try_compile()ing an executable in it. That sub-project is handed the
      # compiler and the flags but not CMAKE_TOOLCHAIN_FILE, so it never sees the
      # sysroot or the wasm32-wasip1 target and always fails here. Answer the
      # question up front instead - wasi-libc has clock_gettime/clock_getres and
      # CLOCK_MONOTONIC - otherwise sundials_profiler.c stops the build with
      # "#error SUNProfiler needs POSIX or Windows timers".
      -DSUNDIALS_POSIX_TIMERS=TRUE
      -DKLU_INCLUDE_DIR=${_suitesparse_sources}/KLU/Include
      -DKLU_LIBRARY=${_suitesparse_ep_build}/KLU/libklu.a
      -DAMD_LIBRARY=${_suitesparse_ep_build}/AMD/libamd.a
      -DCOLAMD_LIBRARY=${_suitesparse_ep_build}/COLAMD/libcolamd.a
      -DBTF_LIBRARY=${_suitesparse_ep_build}/BTF/libbtf.a
      -DSUITESPARSECONFIG_LIBRARY=${_suitesparse_ep_build}/SuiteSparse_config/libsuitesparseconfig.a
    BUILD_COMMAND ${CMAKE_COMMAND} --build ${_sundials_ep_build} --parallel
      --target
      sundials_core_static
      sundials_kinsol_static sundials_idas_static sundials_cvode_static
      sundials_nvecserial_static sundials_sunmatrixdense_static
      sundials_sunmatrixsparse_static sundials_sunlinsoldense_static
      sundials_sunlinsolklu_static
      # The Krylov `-idaLS` solvers and the SUNNonlinearSolver implementations.
      # SUNDIALS bundles a copy of each into every integrator archive, so the
      # wasip1 runtime resolves them either way; an FMU links one side module per
      # solver library, and a symbol with no archive of its own has no group to
      # belong to.
      sundials_sunlinsolspgmr_static sundials_sunlinsolspbcgs_static
      sundials_sunlinsolsptfqmr_static
      sundials_sunnonlinsolnewton_static sundials_sunnonlinsolfixedpoint_static
    INSTALL_COMMAND ""
    BUILD_ALWAYS ON
    EXCLUDE_FROM_ALL ON)
  add_dependencies(rust_sundials_wasm rust_suitesparse_wasm)

  # RUST_SUNDIALS_WASM_DIR is the whole wasm solver hand-off: the archives the
  # wasip1 runtimes link statically and an FMU's PIC side module is linked from,
  # plus the generated headers. A CI stage with only this directory, not the
  # ExternalProject tree, can build every wasm artifact that needs them.
  add_custom_target(rust_sundials_collect
    COMMAND ${CMAKE_COMMAND} -E make_directory ${RUST_SUNDIALS_WASM_DIR}/lib
    COMMAND ${CMAKE_COMMAND} -E copy_directory
      ${_sundials_ep_build}/include ${RUST_SUNDIALS_WASM_DIR}/include
    # copy_if_different: build.rs keys the runtime blobs on these mtimes.
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${_suitesparse_ep_build}/KLU/libklu.a
      ${_suitesparse_ep_build}/UMFPACK/libumfpack.a
      ${_suitesparse_ep_build}/AMD/libamd.a
      ${_suitesparse_ep_build}/COLAMD/libcolamd.a
      ${_suitesparse_ep_build}/BTF/libbtf.a
      ${_suitesparse_ep_build}/SuiteSparse_config/libsuitesparseconfig.a
      ${_sundials_ep_build}/src/sundials/libsundials_core.a
      ${_sundials_ep_build}/src/kinsol/libsundials_kinsol.a
      ${_sundials_ep_build}/src/idas/libsundials_idas.a
      ${_sundials_ep_build}/src/cvode/libsundials_cvode.a
      ${_sundials_ep_build}/src/nvector/serial/libsundials_nvecserial.a
      ${_sundials_ep_build}/src/sunmatrix/dense/libsundials_sunmatrixdense.a
      ${_sundials_ep_build}/src/sunmatrix/sparse/libsundials_sunmatrixsparse.a
      ${_sundials_ep_build}/src/sunlinsol/dense/libsundials_sunlinsoldense.a
      ${_sundials_ep_build}/src/sunlinsol/klu/libsundials_sunlinsolklu.a
      ${_sundials_ep_build}/src/sunlinsol/spgmr/libsundials_sunlinsolspgmr.a
      ${_sundials_ep_build}/src/sunlinsol/spbcgs/libsundials_sunlinsolspbcgs.a
      ${_sundials_ep_build}/src/sunlinsol/sptfqmr/libsundials_sunlinsolsptfqmr.a
      ${_sundials_ep_build}/src/sunnonlinsol/newton/libsundials_sunnonlinsolnewton.a
      ${_sundials_ep_build}/src/sunnonlinsol/fixedpoint/libsundials_sunnonlinsolfixedpoint.a
      ${_lis_ep_build}/liblis.a
      ${_primme_ep_build}/libprimme.a
      ${RUST_SUNDIALS_WASM_DIR}/lib/
    COMMENT "Rust: collecting SUNDIALS/KLU/Lis/PRIMME wasm archives + headers -> ${RUST_SUNDIALS_WASM_DIR}/"
    VERBATIM)
  add_dependencies(rust_sundials_collect rust_sundials_wasm rust_lis_wasm rust_primme_wasm)
endif()

# ---------------------------------------------------------------------------
# HDF5 wasm: MAT v7.3 for the ModelicaExternalC side modules, from the
# openmodelica_hdf5 crate built for wasm32-wasip1. The host build takes the
# system HDF5 instead (ModelicaExternalC's hdf5_native.cmake).
# ---------------------------------------------------------------------------
option(RUST_OMC_ENABLE_HDF5 "Build HDF5 (openmodelica_hdf5 crate) for wasm32-wasip1, so the wasm ModelicaExternalC reads and writes MAT v7.3." ON)
if(RUST_OMC_ENABLE_HDF5)
  # clang wants lib/wasm32-unknown-wasip1/libclang_rt.builtins.a; Debian ships
  # lib/wasi/libclang_rt.builtins-wasm32.a. Symlinks bridge the two so HDF5's
  # configure probes can link -- they must: as compile-only tests (what
  # _wasi_toolchain's CMAKE_TRY_COMPILE_TARGET_TYPE gives SUNDIALS)
  # CHECK_FUNCTION_EXISTS says yes to everything, and H5_HAVE_WAITPID then
  # includes <sys/wait.h>, which no wasi sysroot has.
  set(_hdf5_resdir ${CMAKE_BINARY_DIR}/rust-wasi-clang-resource)
  file(MAKE_DIRECTORY ${_hdf5_resdir}/lib/wasm32-unknown-wasip1)
  file(CREATE_LINK ${_clang_res_dir}/include ${_hdf5_resdir}/include SYMBOLIC)
  file(CREATE_LINK ${_wasi_builtins}
       ${_hdf5_resdir}/lib/wasm32-unknown-wasip1/libclang_rt.builtins.a SYMBOLIC)

  # Declarations wasi-libc withholds while H5private.h uses them anyway. qsort_r
  # it does ship, as a weak symbol with the prototype hidden behind
  # __wasilibc_unmodified_upstream, so HDF5's link probe finds it and the
  # compile then fails on the missing declaration.
  set(_hdf5_shim ${CMAKE_CURRENT_BINARY_DIR}/hdf5-wasi-shim.h)
  file(WRITE ${_hdf5_shim}
    "#include <stddef.h>\n"
    "static inline void tzset(void) {}\n"
    "void qsort_r(void *, size_t, size_t, int (*)(const void *, const void *, void *), void *);\n")

  # hdf5-metno-src forwards only HDF5's try_run() probes, so everything else
  # goes through the cmake crate's CMAKE_TOOLCHAIN_FILE_<target> hook.
  #
  # wasi has neither flock(2) nor fcntl(2) record locks; saying so resolves
  # HDflock() to HDF5's own Nflock(), which just succeeds. Left to the probes,
  # wasi-libc's fcntl() stub is found, the F_SETLK path is compiled, and every
  # H5Fcreate fails with EINVAL -- which H5_IGNORE_DISABLED_FILE_LOCKS does not
  # forgive, it only forgives ENOSYS.
  #
  # ZLIB_SUPPORT is off by default in HDF5 2.x and mandatory here (MATLAB
  # deflates v7.3 datasets). H5_ZLIB_HEADER takes HDF5UseZLIB's "configured by
  # the enclosing project" branch, which needs no zlib library of its own:
  # `inflate` resolves at the side-module link against the ModelicaExternalC
  # zlib both modules already carry.
  set(_hdf5_zlib_src ${CMAKE_CURRENT_SOURCE_DIR}/../SimulationRuntime/ModelicaExternalC/C-Sources/zlib)
  set(_hdf5_toolchain ${CMAKE_CURRENT_BINARY_DIR}/hdf5-wasi-toolchain.cmake)
  file(WRITE ${_hdf5_toolchain}
    "set(CMAKE_SYSTEM_NAME WASI)\n"
    "set(CMAKE_SYSTEM_PROCESSOR wasm32)\n"
    "set(CMAKE_C_COMPILER clang)\n"
    "set(CMAKE_C_COMPILER_TARGET wasm32-wasip1)\n"
    "set(CMAKE_SYSROOT ${RUST_WASI_PIC_SYSROOT})\n"
    "set(CMAKE_AR ${LLVM_AR_EXECUTABLE})\n"
    "set(CMAKE_RANLIB ${LLVM_RANLIB_EXECUTABLE})\n"
    "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)\n"
    "set(H5_HAVE_FLOCK \"\" CACHE INTERNAL \"\")\n"
    "set(H5_HAVE_FCNTL \"\" CACHE INTERNAL \"\")\n"
    # PLUGIN_SUPPORT off does not remove dlopen/dlsym: H5PLpkg.h takes them on
    # any non-Windows target. They are stubbed in external_c_callbacks.c.
    "set(HDF5_ENABLE_PLUGIN_SUPPORT OFF CACHE BOOL \"\" FORCE)\n"
    "set(HDF5_ENABLE_ZLIB_SUPPORT ON CACHE BOOL \"\" FORCE)\n"
    "set(H5_ZLIB_HEADER \"zlib.h\" CACHE STRING \"\" FORCE)\n")

  # -wasm-enable-sjlj only silences wasi-libc's setjmp.h, which #errors on
  # inclusion; HDF5 calls no setjmp, so the archive needs no exception handling.
  set(_hdf5_cflags "-O2 -fPIC -resource-dir=${_hdf5_resdir} -mllvm -wasm-enable-sjlj -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_PROCESS_CLOCKS -D_WASI_EMULATED_MMAN -D_WASI_EMULATED_GETPID -I${_hdf5_zlib_src} -include ${_hdf5_shim}")

  # As for RUST_SUNDIALS_WASM_DIR, a CI stage holding only this directory can
  # build every wasm artifact that needs HDF5.
  set(RUST_HDF5_WASM_DIR ${CMAKE_BINARY_DIR}/rust-hdf5-wasm
      CACHE PATH "Install tree for the HDF5 wasm32-wasip1 archive + headers.")
  add_custom_target(rust_hdf5_wasm
    WORKING_DIRECTORY ${RUST_OMC_DIR}
    JOB_SERVER_AWARE TRUE
    COMMAND ${CMAKE_COMMAND} -E env
            "CMAKE_TOOLCHAIN_FILE_wasm32-wasip1=${_hdf5_toolchain}"
            "CFLAGS_wasm32-wasip1=${_hdf5_cflags}"
            "OMC_HDF5_OUT=${RUST_HDF5_WASM_DIR}"
            ${CARGO_EXECUTABLE} build --release --target wasm32-wasip1 --features library
            --manifest-path ${RUST_OMC_DIR}/openmodelica_hdf5/Cargo.toml
            --target-dir ${CMAKE_BINARY_DIR}/rust-hdf5-cargo
    BYPRODUCTS ${RUST_HDF5_WASM_DIR}/lib/libhdf5.a
    COMMENT "Rust: building HDF5 for wasm32-wasip1 -> ${RUST_HDF5_WASM_DIR}/"
    VERBATIM)
  add_dependencies(rust_hdf5_wasm rust_wasi_pic_sysroot rust_src_sync)
endif()

# The host SUNDIALS and Ipopt archives are collected by
# SimulationRuntime/rust/native_solver_archives.cmake, which runs before this
# file so that libSimulationRuntimeRust gets them without a Rust omc.
get_property(RUST_SUNDIALS_NATIVE_DIR GLOBAL PROPERTY OMC_RUST_SUNDIALS_NATIVE_DIR)
get_property(RUST_SUNDIALS_NATIVE_INDEX_SIZE GLOBAL PROPERTY OMC_RUST_SUNDIALS_INDEX_SIZE)
get_property(RUST_IPOPT_NATIVE_DIR GLOBAL PROPERTY OMC_RUST_IPOPT_NATIVE_DIR)

# ---------------------------------------------------------------------------
# Preview1→preview2 reactor adapter (mandatory for FMI wasm FMU export).
# ---------------------------------------------------------------------------
set(_wasi_p1_adapter ${CMAKE_BINARY_DIR}/downloads/wasi_snapshot_preview1.reactor.wasm)
if(NOT EXISTS ${_wasi_p1_adapter})
  message(STATUS "Downloading wasi_snapshot_preview1 reactor adapter (wasmtime v27.0.0)…")
  file(DOWNLOAD
       https://github.com/bytecodealliance/wasmtime/releases/download/v27.0.0/wasi_snapshot_preview1.reactor.wasm
       ${_wasi_p1_adapter}
       EXPECTED_HASH SHA256=cf26d826c3b1b81faa86c5b6352a725fcf55c50a8806fdf58ba658f675971ff2
       TLS_VERIFY ON STATUS _wasi_p1_dl)
  list(GET _wasi_p1_dl 0 _wasi_p1_code)
  if(NOT _wasi_p1_code EQUAL 0)
    file(REMOVE ${_wasi_p1_adapter})
    message(FATAL_ERROR "Failed to download the wasi preview1 adapter (${_wasi_p1_dl})")
  endif()
endif()

# ---------------------------------------------------------------------------
# CARGO_ENV: env vars forwarded to every cargo invocation.
# Prebuilt artifacts (PIC sysroot, sundials wasm) are passed as output paths
# so the cargo build.rs uses them rather than rebuilding.
# ---------------------------------------------------------------------------
# The revision this omc reports, tagged "-rust" where the C build says "-cmake".
# file(GENERATE), not file(WRITE): it keeps the timestamp when the revision is
# unchanged, so reconfiguring alone rebuilds nothing.
set(RUST_OMC_REVISION_FILE ${CMAKE_CURRENT_BINARY_DIR}/omc-revision.txt)
file(GENERATE OUTPUT ${RUST_OMC_REVISION_FILE} CONTENT "${SOURCE_REVISION_BASE}-rust\n")
list(APPEND CARGO_ENV
     "OMC_RT_LDFLAGS_GENERATED_CODE=${RT_LDFLAGS_GENERATED_CODE}"
     "OMC_RT_LDFLAGS_GENERATED_CODE_SIM=${RT_LDFLAGS_GENERATED_CODE_SIM}"
     "OMC_RT_LDFLAGS_GENERATED_CODE_SIM_RUST=${RT_LDFLAGS_GENERATED_CODE_SIM_RUST}"
     "OMC_RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU=${RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU}"
     "OMC_RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC=${RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC}"
     "OMC_HDF5_LDFLAGS=${OMC_HDF5_LDFLAGS}"
     # The runtime headers openmodelica_simulation_runtime's ABI test compiles;
     # `|`-separated, since a `;` would split the assignment into arguments.
     "OMC_SIMRT_INCLUDE_DIRS=${CMAKE_CURRENT_SOURCE_DIR}/../SimulationRuntime/c|${CMAKE_CURRENT_SOURCE_DIR}/../3rdParty/gc/include"
     # ModelicaExternalC C-Sources dir (the crate builds from a synced copy whose
     # relative path can't reach the real location).
     "OMC_EXTERNAL_C_SOURCES=${CMAKE_CURRENT_SOURCE_DIR}/../SimulationRuntime/ModelicaExternalC/C-Sources"
     # A *path*, not the revision itself: that in the environment would be part
     # of every rustc invocation and miss the whole compilation cache on each
     # commit. Only the leaf openmodelica_revision crate reads the file.
     "OMC_REVISION_FILE=${RUST_OMC_REVISION_FILE}"
     # Prebuilt PIC wasi-libc sysroot (with -fPIC libc.so) built by rust_wasi_pic_sysroot.
     "OMC_WASI_PIC_SYSROOT=${RUST_WASI_PIC_SYSROOT}"
     # Preview1 adapter for FMI wasm FMU export.
     "OMC_WASI_P1_ADAPTER=${_wasi_p1_adapter}")

# Native platforms an exported wasm FMU can also serve
# (`buildModelFMU(..., platforms={"wasm","win64"})`). omc embeds one loader
# library per platform, so each is a cross build of
# `openmodelica_fmi_ls_wasm_to_native` and needs that platform's C toolchain —
# cargo-xwin for the MSVC targets, cargo-zigbuild for Apple and non-host Linux.
# A named target that will not build fails the build (OMC_FMU_NATIVE_OPTIONAL=1
# makes the set best-effort). The host's own platform is always built and need
# not be listed.
set(RUST_OMC_FMU_NATIVE_TARGETS "" CACHE STRING
    "Extra rustc target triples to build FMU loader libraries for (comma-separated).")
if(RUST_OMC_FMU_NATIVE_TARGETS)
  list(APPEND CARGO_ENV "OMC_FMU_NATIVE_TARGETS=${RUST_OMC_FMU_NATIVE_TARGETS}")
endif()
# Loaders from a previous build, reused instead of cross-built again; whatever is
# missing is still built. Same hand-off as RUST_OMC_WASM_RUNTIME.
set(RUST_OMC_FMU_LOADERS "" CACHE PATH
    "Directory of prebuilt FMU loader libraries to reuse (empty = build them).")
if(RUST_OMC_FMU_LOADERS)
  list(APPEND CARGO_ENV "OMC_FMU_LOADERS_IN=${RUST_OMC_FMU_LOADERS}")
endif()
# zig ships no Apple frameworks, so an *-apple-darwin loader needs an SDK.
set(RUST_OMC_MACOS_SDK "" CACHE PATH
    "macOS SDK for the *-apple-darwin FMU loaders (MacOSX<version>.sdk).")
if(RUST_OMC_MACOS_SDK)
  list(APPEND CARGO_ENV "OMC_FMU_MACOS_SDK=${RUST_OMC_MACOS_SDK}")
endif()
# The libraries themselves are not linked into omc — a native one reads them from
# lib/omc/fmu-loaders, the browser one fetches them from the web bundle — so the
# build script drops them here for CMake to install.
set(RUST_FMU_LOADERS_DIR ${CMAKE_CURRENT_BINARY_DIR}/fmu-loaders)
list(APPEND CARGO_ENV "OMC_FMU_LOADERS_OUT=${RUST_FMU_LOADERS_DIR}")

if(RUST_OMC_ENABLE_SUNDIALS)
  list(APPEND CARGO_ENV "OMC_SUNDIALS_WASM_DIR=${RUST_SUNDIALS_WASM_DIR}")
  # Off leaves the omc cdylib without the wasm-jit sundials feature, so it does
  # not get the host archives either; libSimulationRuntimeRust still does.
  if(RUST_SUNDIALS_NATIVE_DIR)
    list(APPEND CARGO_ENV
         "OMC_SUNDIALS_NATIVE_DIR=${RUST_SUNDIALS_NATIVE_DIR}"
         "OMC_SUNDIALS_NATIVE_INDEX_SIZE=${RUST_SUNDIALS_NATIVE_INDEX_SIZE}")
  endif()
endif()
if(RUST_OMC_ENABLE_HDF5)
  # The HDF5 install tree the ModelicaExternalC side modules compile and link
  # against; unset, they are built without HAVE_HDF5 and reject v7.3 files.
  list(APPEND CARGO_ENV "OMC_WASM_HDF5_DIR=${RUST_HDF5_WASM_DIR}")
endif()

if(TARGET rust_ipopt_native_collect)
  list(APPEND CARGO_ENV "OMC_IPOPT_NATIVE_DIR=${RUST_IPOPT_NATIVE_DIR}")
endif()

# Source paths (fallback for raw cargo builds without CMake).
if(EXISTS ${_wasi_libc_src}/CMakeLists.txt)
  list(APPEND CARGO_ENV "OMC_WASI_LIBC_SRC=${_wasi_libc_src}")
endif()

# ---------------------------------------------------------------------------
# wasm-opt, found once and used by the web target, the wasm-jit runtime and --
# through the cargo environment below -- openmodelica_wasm_jit's build script.
# ---------------------------------------------------------------------------
find_program(WASM_OPT_EXECUTABLE wasm-opt
             HINTS $ENV{CARGO_HOME}/bin $ENV{HOME}/.cargo/bin)
# wasm-opt -Oz on the 130+ MB debug/omc wasm takes many minutes and only shrinks
# the shipped bundle — skip it for dev iteration. Clearing the executable var makes
# every `if(WASM_OPT_EXECUTABLE)` site below fall through to the no-op branch.
option(RUST_OMC_WASM_OPT "Run wasm-opt -Oz on the produced wasm (slow; OFF for faster dev builds)" ON)
if(NOT RUST_OMC_WASM_OPT)
  set(WASM_OPT_EXECUTABLE "")
  message(STATUS "rust_omc: wasm-opt disabled (RUST_OMC_WASM_OPT=OFF)")
endif()

# wasm-opt feature flags, shared by every wasm-opt invocation below. rustc/LLVM
# emit wasm32-unknown-unknown with these post-MVP features on, but the release
# `strip` drops the target_features custom section binaryen would auto-detect
# from — so it defaults to MVP and rejects the bulk-memory/sign-ext/etc. ops.
# Enable exactly the set rustc reports (`rustc --print cfg --target
# wasm32-unknown-unknown`), plus `simd`: faer's kernels are
# `#[target_feature(enable = "simd128")]`, so every module linking them carries
# v128 ops. Blindly enabling the rest could let wasm-opt emit instructions the
# JIT/browser consumers don't support.
set(WASM_OPT_FEATURES
    --enable-bulk-memory --enable-multivalue --enable-mutable-globals
    --enable-nontrapping-float-to-int --enable-reference-types --enable-sign-ext
    --enable-simd)

# The FMI3 adapters and the solver side modules are produced inside
# openmodelica_wasm_jit's build script rather than by a CMake command, so it runs
# wasm-opt itself. Every exported FMU links those modules and they are built once per
# omc build and stamped, so this is paid here instead of per export. Empty when
# binaryen is missing or RUST_OMC_WASM_OPT is OFF.
string(JOIN " " _wasm_opt_features ${WASM_OPT_FEATURES})
list(APPEND CARGO_ENV
     "OMC_WASM_OPT=${WASM_OPT_EXECUTABLE}"
     "OMC_WASM_OPT_FEATURES=${_wasm_opt_features}")

# Always via ${CARGO_BUILD} so target/ is never the in-source default.
set(CARGO_BUILD ${CARGO_ENV} ${CARGO_EXECUTABLE} build --target-dir ${RUST_TARGET_DIR})
# The build tools (mmtorust, susan, scripting_api_gen) always run on and target
# the host, so they use ${CARGO_BUILD} and live in target/<profile>/.
set(SUSAN_BIN   ${RUST_TARGET_DIR}/release/susan)
set(MMTORUST_BIN ${RUST_TARGET_DIR}/release/mmtorust)

# ${CARGO_BUILD_ARTIFACT}: the cargo invocation for the omc *artifacts* (cdylib,
# launcher, native GUI clients). Identical to ${CARGO_BUILD} for a native build;
# for a cross build (RUST_OMC_TARGET set) it becomes `cargo xwin build --target
# <triple>`, which wraps cargo with clang-cl + the cached MSVC CRT/SDK. cargo-xwin
# is a separate cargo subcommand binary; require it up front when cross.
if(RUST_OMC_TARGET)
  find_program(CARGO_XWIN_EXECUTABLE cargo-xwin REQUIRED
               HINTS $ENV{CARGO_HOME}/bin $ENV{HOME}/.cargo/bin)
  set(CARGO_BUILD_ARTIFACT ${CARGO_ENV} XWIN_ACCEPT_LICENSE=1
      ${CARGO_EXECUTABLE} xwin build --target ${RUST_OMC_TARGET} --target-dir ${RUST_TARGET_DIR})
else()
  set(CARGO_BUILD_ARTIFACT ${CARGO_BUILD})
endif()

# ---------------------------------------------------------------------------
# ctest: run the workspace's cargo tests. The top-level CMakeLists already calls
# include(CTest)/enable_testing(), so this registers a CTest test and CI can do
# `cmake --build . && ctest`. The unit tests use the default dev profile (the
# cranelift backend, opt-level 0) — far faster to compile than the release
# artifacts — not RUST_OMC_PROFILE. --workspace covers every crate's tests. The
# test does not run codegen itself, so the omc targets must be built first (CTest
# has no build dependency on them) — the standard build-then-ctest order.
#
# `openmodelica` is excluded: it is the thin omc launcher, which links against
# libOpenModelicaCompiler.so of the *build's* profile. That library is only ever
# produced in RUST_OMC_PROFILE, so building the package's test target in the dev
# profile fails to link. It carries no tests of its own.
# ---------------------------------------------------------------------------
add_test(NAME rust_cargo_test
  COMMAND ${CARGO_ENV} ${CARGO_EXECUTABLE} test --target-dir ${RUST_TARGET_DIR}
          --workspace --exclude openmodelica
  WORKING_DIRECTORY ${RUST_OMC_DIR})

# ---------------------------------------------------------------------------
# wasm-jit runtime artifact (CI hand-off). The wasm-jit simCodeTarget embeds a
# precompiled linear-memory runtime (the openmodelica_codegen_wasm_jit_runtime
# crate, a standalone wasm32 cdylib) into the compiler via include_bytes!.
# Normally that crate's build.rs builds it on demand during *any* omc build
# (native or wasm); it never runs the wasm-opt binary on it.
#
# Two knobs let a multi-stage CI build it once, optimise it, and reuse it:
#   * rust_wasm_runtime (target): build the runtime crate for wasm32 and, if
#     binaryen is present, `wasm-opt -Oz` it, writing RUST_OMC_WASM_RUNTIME_OUT.
#     Stage 1 (a normal native Rust build) runs this and archives the output.
#   * RUST_OMC_WASM_RUNTIME (cache path): a prebuilt runtime.wasm to embed
#     instead of rebuilding. Stage 2 (the web build) sets it to stage 1's
#     artifact; it is forwarded as OMC_WASM_RUNTIME to the cargo build, which the
#     build.rs honours (skipping the rebuild). Empty = build it normally.
# ---------------------------------------------------------------------------

# Independent of RUST_OMC_WASM_OPT (which only gates omc.wasm -Oz): an -O0 OMEdit
# link does not run in the browser, so keep it ON even for PR builds.
option(OMEDIT_WASM_OPTIMIZE "Optimize OMEdit-qt.wasm at link (-O0 does not run in-browser; OFF only for dev)" ON)

# Split the slow Qt web pages (OMShell/OMNotebook/OMEdit-qt) into their own stage:
# OFF drops them from the web build, STANDALONE builds them off a prebuilt omc.
option(RUST_OMC_WEB_QT "Include the Qt web pages in the web build" ON)
option(RUST_OMC_WEB_QT_STANDALONE "Build the Qt web pages alone, reusing a prebuilt omc" OFF)
if(RUST_OMC_WEB_QT_STANDALONE)
  set(_qt_web_all "")  # built via --target in the standalone stage, not ALL
else()
  set(_qt_web_all ALL)
endif()
set(RUST_OMC_WASM_RUNTIME "" CACHE FILEPATH
    "Prebuilt wasm-jit runtime.wasm to embed (empty = build it). In CI stage 2, point at the rust_wasm_runtime artifact from stage 1.")
set(RUST_OMC_WASM_RUNTIME_OUT ${RUST_OMC_TARGET_DIR}/runtime.wasm CACHE PATH
    "Output path of the rust_wasm_runtime target (the built + wasm-opt'd wasm-jit runtime).")

set(_wasm_jit_runtime_dir ${RUST_OMC_DIR}/openmodelica_codegen_wasm_jit_runtime)
set(_wasm_jit_runtime_target_dir ${RUST_OMC_TARGET_DIR}/wasm-jit-runtime)
set(_wasm_jit_runtime_wasm
    ${_wasm_jit_runtime_target_dir}/wasm32-unknown-unknown/release/openmodelica_codegen_wasm_jit_runtime.wasm)
if(WASM_OPT_EXECUTABLE)
  set(_wasm_jit_runtime_opt COMMAND ${WASM_OPT_EXECUTABLE} -Oz ${WASM_OPT_FEATURES}
      ${RUST_OMC_WASM_RUNTIME_OUT} -o ${RUST_OMC_WASM_RUNTIME_OUT})
else()
  set(_wasm_jit_runtime_opt "")
endif()
# Standalone [workspace] crate, so build it directly (no codegen dependency); its
# own target-dir keeps it from contending with the main build's lock.
add_custom_target(rust_wasm_runtime
  WORKING_DIRECTORY ${_wasm_jit_runtime_dir}
  JOB_SERVER_AWARE TRUE
  COMMAND ${CARGO_ENV} ${CARGO_EXECUTABLE} build --release
          --target wasm32-unknown-unknown --target-dir ${_wasm_jit_runtime_target_dir}
  COMMAND ${CMAKE_COMMAND} -E copy ${_wasm_jit_runtime_wasm} ${RUST_OMC_WASM_RUNTIME_OUT}
  ${_wasm_jit_runtime_opt}
  COMMENT "Rust: building + optimising the wasm-jit runtime -> ${RUST_OMC_WASM_RUNTIME_OUT}"
  VERBATIM)
add_dependencies(rust_wasm_runtime rust_src_sync)

# ---------------------------------------------------------------------------
# Autoconf.mo is a generated compiler source (configure_file from
# Autoconf.mo.in; the actual generation is in Compiler/CMakeLists.txt, which has
# the substitution vars). It is written to the BUILD tree, not Compiler/Util —
# an in-source Compiler/Util/Autoconf.mo collides with a parallel autotools build
# of the same checkout. The two mmtorust source lists (the full
# rust_compilerSources.txt built in omc_rust_setup_codegen, and the susan subset
# below) reference the in-source Util/Autoconf.mo, so each redirects that one
# entry to RUST_AUTOCONF_MO. mmtorust routes classes to crates by their
# `__OpenModelica_Interface` annotation, not the file path, so the build-tree
# location is transparent.
# ---------------------------------------------------------------------------
set(RUST_AUTOCONF_MO ${CMAKE_CURRENT_BINARY_DIR}/generated-mo/Autoconf.mo
    CACHE INTERNAL "Build-tree Autoconf.mo (generated out of the source tree).")

# Build-tree copy of susanSources.txt: redirect the Autoconf.mo entry to
# RUST_AUTOCONF_MO and resolve the other ../-relative entries to absolute source
# paths (mmtorust now runs in the per-build copy, so ../ no longer reaches them).
# file(READ)+string(REPLACE), not file(STRINGS): the latter splits lines on the
# header's em-dash. copy_if_different keeps the mtime stable across reconfigures.
set(RUST_SUSAN_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/rust_susanSources.txt)
file(READ ${RUST_OMC_SRC_DIR}/susanSources.txt _susan_content)
string(REPLACE "../Util/Autoconf.mo" "${RUST_AUTOCONF_MO}" _susan_content "${_susan_content}")
string(REPLACE "../" "${CMAKE_CURRENT_SOURCE_DIR}/" _susan_content "${_susan_content}")
file(WRITE ${RUST_SUSAN_SOURCES}.tmp "${_susan_content}")
execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${RUST_SUSAN_SOURCES}.tmp ${RUST_SUSAN_SOURCES})

# ---------------------------------------------------------------------------
# Step 1+2: build mmtorust (release), transpile the Susan subset, build susan.
# A stamp file marks completion; cargo itself handles incremental rebuilds, so
# the command is a fast no-op when only some of its inputs changed.
#
# The stamp has to name those inputs: a stamp rule with no DEPENDS is up to date
# the moment the file exists, so the rule never runs a second time and every
# later build compiles the templates with the `susan` of the first one.
# ---------------------------------------------------------------------------
file(GLOB_RECURSE SUSAN_TOOL_SOURCES CONFIGURE_DEPENDS ${RUST_OMC_DIR}/mmtorust/src/*.rs)
list(APPEND SUSAN_TOOL_SOURCES
     ${RUST_OMC_DIR}/mmtorust/Cargo.toml
     ${RUST_OMC_DIR}/openmodelica_susan/Cargo.toml
     ${RUST_OMC_DIR}/openmodelica_susan/src/main.rs)
# The subset's *.mo: the rest of openmodelica_susan/src is transpiled from them.
file(STRINGS ${RUST_SUSAN_SOURCES} SUSAN_SUBSET_MO REGEX "\\.mo$")
set(SUSAN_STAMP ${CMAKE_CURRENT_BINARY_DIR}/rust_susan.stamp)
add_custom_command(
  OUTPUT ${SUSAN_STAMP}
  WORKING_DIRECTORY ${RUST_OMC_DIR}
  # Hand make's -jN jobserver tokens to cargo (needs CMake >= 3.28).
  JOB_SERVER_AWARE TRUE
  # Build tools always in release.
  COMMAND ${CARGO_BUILD} --release -p mmtorust
  # `--sources <susan subset>` is exactly what the `susan` subcommand does (it
  # only picks that default list); pass the build-tree list so Autoconf.mo
  # resolves to its build-tree copy rather than the in-source path.
  COMMAND ${MMTORUST_BIN} --sources ${RUST_SUSAN_SOURCES}
  COMMAND ${CARGO_BUILD} --release -p openmodelica_susan --bin susan
  COMMAND ${CMAKE_COMMAND} -E touch ${SUSAN_STAMP}
  DEPENDS ${SUSAN_TOOL_SOURCES} ${SUSAN_SUBSET_MO} ${RUST_SUSAN_SOURCES}
  COMMENT "Rust: building mmtorust + Susan template compiler (release)"
  VERBATIM)
add_custom_target(rust_susan DEPENDS ${SUSAN_STAMP})
add_dependencies(rust_susan rust_src_sync)

# In Rust mode the template rules (omc_add_template_target) invoke ${OMC_EXE} on
# each *.tpl; point it at susan and make each *.mo rule depend on rust_susan via
# TPL_EXTRA_DEPENDS (consumed by the macro).
set(OMC_EXE ${SUSAN_BIN})
set(TPL_EXTRA_DEPENDS ${SUSAN_STAMP})

# ---------------------------------------------------------------------------
# Step 4: full transpile. Depends on every template-generated *.mo
# (TPL_OUTPUT_MO_FILES, populated by template_compilation.cmake) plus the
# scripting-API .mo (generated below by the standalone scripting_api_gen tool).
# ---------------------------------------------------------------------------
function(omc_rust_setup_codegen)
  # Use the canonical CMake source list (meta_modelica_source_list.cmake), the
  # same set the C build compiles, instead of a separate hardcoded
  # compilerSources.txt — so the Rust build can never drift from it (e.g. the
  # wasm-jit files added in #15847 are picked up automatically). We materialise
  # it to a file and pass `mmtorust --sources`. Absolute paths are fine; mmtorust
  # writes its output relative to its working directory (the crate tree).
  set(RUST_SOURCES_FILE ${CMAKE_CURRENT_BINARY_DIR}/rust_compilerSources.txt)
  set(_rust_src_content "# Generated by rust_omc.cmake from meta_modelica_source_list.cmake.\n# Do not edit by hand — the canonical list is the CMake one.\n")
  # Also collect the .mo files as codegen dependencies (RUST_MO_SOURCES): the
  # transpile must re-run when any hand-written source changes, not only when the
  # list file / templates change (else editing e.g. CevalScriptBackend.mo is a
  # silent no-op — cargo sees unchanged .rs and does nothing).
  set(RUST_MO_SOURCES "")
  foreach(_f ${OMC_MM_ALWAYS_SOURCES} ${OMC_MM_BACKEND_SOURCES})
    # Redirect the in-source Util/Autoconf.mo to the build-tree copy (see
    # RUST_AUTOCONF_MO above); it isn't generated into Compiler/Util in Rust mode.
    if(_f MATCHES "Util/Autoconf\\.mo$")
      string(APPEND _rust_src_content "${RUST_AUTOCONF_MO}\n")
      list(APPEND RUST_MO_SOURCES ${RUST_AUTOCONF_MO})
    else()
      string(APPEND _rust_src_content "${_f}\n")
      list(APPEND RUST_MO_SOURCES ${_f})
    endif()
  endforeach()
  # copy_if_different so the mtime (which rust_codegen DEPENDS on) only moves on
  # a real change — a plain file(WRITE) would rewrite it every reconfigure.
  file(WRITE ${RUST_SOURCES_FILE}.tmp "${_rust_src_content}")
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different
                  ${RUST_SOURCES_FILE}.tmp ${RUST_SOURCES_FILE})

  # -------------------------------------------------------------------------
  # Generate Script/OpenModelicaScriptingAPI.mo (the typed thin wrappers around
  # the interactive API) WITHOUT a built omc, breaking the bootstrap cycle: omc
  # links libOpenModelicaCompiler.so, whose openmodelica_scripting_qt crate is
  # mmtorust-generated *from this .mo*; in the C build the .mo came from running
  # omc itself (OpenModelica.Scripting.generateScriptingAPI), which the Rust port
  # cannot do before omc exists. The standalone `scripting_api_gen` tool depends
  # only on the hand-written parser crate (openmodelica_ast, not generated), so it
  # builds and runs with no prior codegen. It parses the OpenModelica.Scripting
  # package out of FrontEnd/ModelicaBuiltin.mo and emits the .mo directly (no Tpl,
  # no Lookup). The Qt .cpp/.h are emitted later by mmtorust (emit_scripting_api_qt).
  #
  # DEPENDS on ModelicaBuiltin.mo so the API is regenerated whenever the builtin
  # OpenModelica.Scripting package changes, and on the generator's own source.
  set(SCRIPTING_API_MO ${CMAKE_CURRENT_SOURCE_DIR}/Script/OpenModelicaScriptingAPI.mo)
  set(MODELICA_BUILTIN_MO ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ModelicaBuiltin.mo)
  add_custom_command(
    OUTPUT ${SCRIPTING_API_MO}
    WORKING_DIRECTORY ${RUST_OMC_DIR}
    JOB_SERVER_AWARE TRUE
    COMMAND ${CARGO_BUILD} --release -p openmodelica_scripting_api_gen
    COMMAND ${RUST_TARGET_DIR}/release/scripting_api_gen ${MODELICA_BUILTIN_MO} ${SCRIPTING_API_MO}
    DEPENDS ${MODELICA_BUILTIN_MO}
            ${RUST_OMC_DIR}/openmodelica_scripting_api_gen/src/main.rs
    COMMENT "Rust: generating OpenModelicaScriptingAPI.mo from ModelicaBuiltin.mo (no omc)"
    VERBATIM)
  add_custom_target(rust_scripting_api DEPENDS ${SCRIPTING_API_MO})
  add_dependencies(rust_scripting_api rust_src_sync)

  # mmtorust emits OMEdit's C++ Qt scripting-API here (build tree); OMEditLIB reads it.
  set(OMC_SCRIPTING_API_QT_DIR ${CMAKE_CURRENT_BINARY_DIR}/scripting-api-qt
      CACHE INTERNAL "Generated OpenModelicaScriptingAPIQt C++ sources (build tree)")

  set(CODEGEN_STAMP ${CMAKE_CURRENT_BINARY_DIR}/rust_codegen.stamp)
  # The generated *.rs depend on how mmtorust lowers, not only on the *.mo it
  # lowers; without these a transpiler change leaves stale *.rs in place.
  file(GLOB_RECURSE MMTORUST_SOURCES CONFIGURE_DEPENDS
       ${RUST_OMC_DIR}/mmtorust/src/*.rs)
  list(APPEND MMTORUST_SOURCES ${RUST_OMC_DIR}/mmtorust/Cargo.toml)
  if(RUST_OMC_PREBUILT_GENERATED_SRC)
    # Stamp completion with no dependency on the transpile chain, so mmtorust /
    # susan / the templates are never built; the .rs are already in the tree.
    add_custom_command(
      OUTPUT ${CODEGEN_STAMP}
      COMMAND ${CMAKE_COMMAND} -E touch ${CODEGEN_STAMP}
      COMMENT "Rust: reusing prebuilt generated sources (RUST_OMC_PREBUILT_GENERATED_SRC)"
      VERBATIM)
    add_custom_target(rust_codegen DEPENDS ${CODEGEN_STAMP})
    add_dependencies(rust_codegen rust_src_sync)
    return()
  endif()
  add_custom_command(
    OUTPUT ${CODEGEN_STAMP}
    WORKING_DIRECTORY ${RUST_OMC_DIR}
    JOB_SERVER_AWARE TRUE
    COMMAND ${CARGO_BUILD} --release -p mmtorust
    # Strip unused `import X;` from the Susan-generated *.mo before transpiling:
    # mmtorust lowers every import to a `use crate::X`, so an unused import
    # becomes a `use` of a crate the target does not depend on (e.g.
    # `openmodelica_backend::SimCodeUtil` in openmodelica_codegen_xml). The C
    # build runs the same boot/find-unused-import.sh. It exits non-zero when it
    # removes something, so `; true` keeps the build going.
    COMMAND bash -c "\"$0\" \"$@\" ; true" ${CMAKE_CURRENT_SOURCE_DIR}/boot/find-unused-import.sh ${TPL_OUTPUT_MO_FILES}
    COMMAND ${CMAKE_COMMAND} -E env OMC_SCRIPTING_API_QT_OUT=${OMC_SCRIPTING_API_QT_DIR}
            ${MMTORUST_BIN} --sources ${RUST_SOURCES_FILE}
    COMMAND ${CMAKE_COMMAND} -E touch ${CODEGEN_STAMP}
    DEPENDS ${TPL_OUTPUT_MO_FILES} ${SUSAN_STAMP} ${RUST_SOURCES_FILE}
            ${CMAKE_CURRENT_SOURCE_DIR}/Script/OpenModelicaScriptingAPI.mo
            ${RUST_MO_SOURCES} ${MMTORUST_SOURCES}
    COMMENT "Rust: transpiling all MetaModelica sources (mmtorust --sources <cmake list>)"
    VERBATIM)
  add_custom_target(rust_codegen DEPENDS ${CODEGEN_STAMP})
  add_dependencies(rust_codegen rust_src_sync)

  # The native omc artifacts (and their install rules) are pointless for the
  # wasm/web target — it ships a single .wasm bundle, not the cdylib + launcher —
  # so in wasm mode they are not defined at all, leaving `make all` to build only
  # the wasm bundle (omc_rust_setup_wasm). The codegen above is still needed: the
  # wasm crate is built from the same generated .rs.
  if(NOT OM_OMC_WASM)
  # -------------------------------------------------------------------------
  # Code-generation target features for the cdylib (forwarded to
  # openmodelica_backend_main). mmtorust gates every reference to a disabled
  # target crate (the dispatch bails/panics), so a dropped target is neither
  # compiled nor linked. The native default set is C, C++ and FMU:
  #   * `cpp` is dropped when the C++ simulation runtime is not built
  #     (OM_OMC_ENABLE_CPP_RUNTIME=OFF) — there is nothing for the generated
  #     C++ sources to compile against.
  #   * `scripting_api` (the generated OMEdit C-ABI) is added when
  #     RUST_OMC_SCRIPTING_API is set (defaults to OM_ENABLE_GUI_CLIENTS), since
  #     OMEdit links those #[no_mangle] symbols out of this cdylib. A split CI can
  #     force it ON to ship those symbols even with the GUI subdirs OFF.
  # `--no-default-features` lets the list below be authoritative (the wasm-jit
  # target is always present and is not a feature). codegen_fmu_c is the FMU C
  # export; it implies codegen_fmu (the modelDescription.xml templates) and
  # codegen_c in the crate's feature table.
  set(_rust_omc_features codegen_c codegen_fmu_c)
  if(OM_OMC_ENABLE_CPP_RUNTIME)
    list(APPEND _rust_omc_features cpp)
  endif()
  if(RUST_OMC_SCRIPTING_API)
    list(APPEND _rust_omc_features scripting_api)
  endif()
  # Run the wasm-jit simulations on wasmer rather than wasmtime: the web target's
  # own host code (`sim_runtime_wasmer.rs`, the ModelicaExternalC side module),
  # which is otherwise reachable only from a browser.
  option(RUST_OMC_ENGINE_WASMER "Build the native omc with the wasmer wasm-jit host (the web target's) instead of wasmtime." OFF)
  if(RUST_OMC_ENGINE_WASMER)
    list(APPEND _rust_omc_features engine-wasmer)
  endif()
  # --no-default-features makes sundials off by default; enable it only when
  # the wasm cross-compile is enabled.
  if(RUST_OMC_ENABLE_SUNDIALS)
    list(APPEND _rust_omc_features openmodelica_codegen_wasm_jit/sundials)
  endif()
  # Cross builds keep the system allocator: mimalloc compiles C sources.
  if(RUST_OMC_TARGET STREQUAL "")
    set(_rust_omc_allocator_default "mimalloc")
  else()
    set(_rust_omc_allocator_default "system")
  endif()
  set(RUST_OMC_ALLOCATOR "${_rust_omc_allocator_default}"
      CACHE STRING "Global allocator for the Rust omc: system, mimalloc or jemalloc.")
  set_property(CACHE RUST_OMC_ALLOCATOR PROPERTY STRINGS system mimalloc jemalloc)
  if(NOT RUST_OMC_ALLOCATOR STREQUAL "system")
    list(APPEND _rust_omc_features ${RUST_OMC_ALLOCATOR})
  endif()
  list(JOIN _rust_omc_features "," _rust_omc_features_csv)
  set(RUST_OMC_CDYLIB_FEATURES --no-default-features --features ${_rust_omc_features_csv})

  # -------------------------------------------------------------------------
  # Step 5: build the omc artifacts with the selected profile. Both are part of
  # `all` (ALL) so a plain `make` produces them and `make install` can stage
  # them — exactly like the C build's omc/OpenModelicaCompiler targets, which the
  # rust branch skips. rust_libopenmodelica builds the
  # target/<profile>/libOpenModelicaCompiler.so that gets installed; rust_omc
  # builds the thin launcher, which links that same .so as an external prebuilt
  # library (its build.rs finds it in the profile dir), so it must be built
  # after — hence rust_omc's DEPENDS on rust_libopenmodelica.
  # -------------------------------------------------------------------------
  add_custom_target(rust_libopenmodelica ALL
    WORKING_DIRECTORY ${RUST_OMC_DIR}
    JOB_SERVER_AWARE TRUE
    COMMAND ${CARGO_BUILD_ARTIFACT} ${RUST_OMC_PROFILE_FLAG} ${RUST_OMC_TIMINGS_FLAG} ${RUST_OMC_CDYLIB_FEATURES} -p libopenmodelica_compiler
    # Declares THIS target as the producer of the cdylib (consumed via the
    # IMPORTED OpenModelicaCompiler target's IMPORTED_LOCATION). Enough for Ninja,
    # which tracks byproducts globally; the cross-directory build order for the
    # Unix Makefiles generator is the add_dependencies in omc_rust_setup_omedit.
    BYPRODUCTS ${RUST_TARGET_DIR}/${RUST_OMC_ARTIFACT_SUBDIR}/${RUST_OMC_CDYLIB_NAME}
    DEPENDS rust_codegen rust_wasi_pic_sysroot
    COMMENT "Rust: building ${RUST_OMC_CDYLIB_NAME} (${RUST_OMC_PROFILE})"
    VERBATIM)
  if(RUST_OMC_ENABLE_SUNDIALS)
    add_dependencies(rust_libopenmodelica rust_sundials_collect)
    if(TARGET rust_sundials_native_collect)
      add_dependencies(rust_libopenmodelica rust_sundials_native_collect)
    endif()
  endif()
  if(RUST_OMC_ENABLE_HDF5)
    add_dependencies(rust_libopenmodelica rust_hdf5_wasm)
  endif()
  if(TARGET rust_ipopt_native_collect)
    add_dependencies(rust_libopenmodelica rust_ipopt_native_collect)
  endif()

  add_custom_target(rust_omc ALL
    WORKING_DIRECTORY ${RUST_OMC_DIR}
    JOB_SERVER_AWARE TRUE
    COMMAND ${CARGO_BUILD_ARTIFACT} ${RUST_OMC_PROFILE_FLAG} ${RUST_OMC_TIMINGS_FLAG} -p openmodelica
    DEPENDS rust_codegen rust_libopenmodelica
    COMMENT "Rust: building omc (cargo build -p openmodelica, ${RUST_OMC_PROFILE})"
    VERBATIM)

  # -------------------------------------------------------------------------
  # Install into the standard layout, mirroring the C build's install rules
  # (OMCompiler/Compiler/CMakeLists.txt, skipped in rust mode): the omc launcher
  # → bin/, the cdylib → ${CMAKE_INSTALL_LIBDIR} (lib/<triple>/omc, next to the
  # simulation-runtime libs installed by OMCompiler/SimulationRuntime under the
  # same `omc` component), and the *Builtin.mo files → lib/omc/. The launcher's
  # rpath ($ORIGIN/../lib/<triple>/omc) then resolves both the cdylib and the
  # dlopened runtime libs. Build the targets first: `make && make install`.
  # -------------------------------------------------------------------------
  set(RUST_OMC_ARTIFACT_DIR ${RUST_TARGET_DIR}/${RUST_OMC_ARTIFACT_SUBDIR})
  install(PROGRAMS ${RUST_OMC_ARTIFACT_DIR}/openmodelica${RUST_OMC_EXE_SUFFIX}
          DESTINATION ${CMAKE_INSTALL_BINDIR} RENAME omc${RUST_OMC_EXE_SUFFIX} COMPONENT omc)
  # Windows resolves a DLL from the executable's directory, so the cdylib is
  # installed next to omc.exe in bin/; unix puts the .so under lib/<triple>/omc
  # (next to the simulation-runtime libs) where the launcher's rpath finds it.
  if(RUST_OMC_TARGET MATCHES "windows")
    install(PROGRAMS ${RUST_OMC_ARTIFACT_DIR}/${RUST_OMC_CDYLIB_NAME}
            DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT omc)
  else()
    install(PROGRAMS ${RUST_OMC_ARTIFACT_DIR}/${RUST_OMC_CDYLIB_NAME}
            DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT omc)
  endif()

  # The FMI 3.0 loader libraries an exported wasm FMU is given for a native
  # platform. Read at export time, not linked into omc.
  install(DIRECTORY ${RUST_FMU_LOADERS_DIR}/
          DESTINATION lib/omc/fmu-loaders COMPONENT omc)

  # The wasm-jit runtime, the FMI adapter and the external "C" side libraries,
  # compiled here rather than by whoever runs omc first: the per-user cache is
  # filled lazily, so parallel omc processes each compile them before any writes
  # one. `aot_module` reads this directory before `$HOME/.openmodelica/cache`.
  # No OUTPUT to go stale on: the artifacts are keyed by a hash of the blobs, so
  # one left behind by an earlier omc is never looked up again and the run it was
  # meant to spare compiles instead. omc skips a blob whose artifact is current,
  # so a build that changed none of them costs the process start.
  set(RUST_WASMJIT_CACHE_DIR ${CMAKE_CURRENT_BINARY_DIR}/wasmjit-cache)
  add_custom_target(rust_wasmjit_cache ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory ${RUST_WASMJIT_CACHE_DIR}
    COMMAND ${CMAKE_COMMAND} -E env
            OMC_WASM_PRECOMPILE_CACHE=${RUST_WASMJIT_CACHE_DIR}
            ${RUST_OMC_ARTIFACT_DIR}/openmodelica${RUST_OMC_EXE_SUFFIX}
    DEPENDS rust_libopenmodelica
    COMMENT "Precompiling the wasm-jit artifacts"
    VERBATIM)
  add_dependencies(rust_wasmjit_cache rust_omc)
  install(DIRECTORY ${RUST_WASMJIT_CACHE_DIR}/
          DESTINATION lib/omc/cache COMPONENT omc
          FILES_MATCHING PATTERN "*.cwasm")

  # The PIC wasi-libc sysroot an external "C" library for wasm-jit is compiled
  # against. Under the wasm triple with an `omc` subdirectory so it cannot be
  # confused with a distribution's /usr/lib/wasm32-wasi, and with the compiler-rt
  # builtins so it matches the libc.so omc resolves imports against.
  install(DIRECTORY ${RUST_WASI_PIC_SYSROOT}/
          DESTINATION lib/wasm32-wasi/omc COMPONENT omc)
  if(_wasi_builtins)
    install(FILES ${_wasi_builtins}
            DESTINATION lib/wasm32-wasi/omc/lib/wasm32-wasip1 COMPONENT omc)
  endif()

  # The toolchain omc hands a library's CMake build project when it has to build
  # that library's external "C" for wasm. Names only, so the install relocates.
  get_filename_component(RUST_OMC_WASI_CLANG "${_omc_wasi_clang}" NAME)
  get_filename_component(RUST_OMC_LLVM_AR "${LLVM_AR_EXECUTABLE}" NAME)
  get_filename_component(RUST_OMC_LLVM_RANLIB "${LLVM_RANLIB_EXECUTABLE}" NAME)
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/.cmake/wasm32-wasip1-toolchain.cmake.in
                 ${CMAKE_CURRENT_BINARY_DIR}/wasm32-wasip1.cmake @ONLY)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/wasm32-wasip1.cmake
          DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omc/cmake COMPONENT omc)
  install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/wasm32-wasip1-rules.cmake
          DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omc/cmake COMPONENT omc)

  # The desktop egui OMShell client (omshell_egui). It links the compiler
  # in-process as an ordinary cargo dependency (omshell_omc ->
  # openmodelica_backend_main), so building it compiles the compiler crates too;
  # hence the DEPENDS on rust_codegen (the generated sources must exist first).
  # The browser build of OMShell is handled by the wasm target.
  if(OM_ENABLE_GUI_CLIENTS AND RUST_OMC_OMSHELL_CLIENTS)
    # Serialised after rust_omc: concurrent cargo-xwin runs race on the shared clang-cl wrapper.
    add_custom_target(rust_omshell_egui ALL
      WORKING_DIRECTORY ${RUST_OMC_DIR}
      JOB_SERVER_AWARE TRUE
      COMMAND ${CARGO_BUILD_ARTIFACT} ${RUST_OMC_PROFILE_FLAG} ${RUST_OMC_TIMINGS_FLAG} -p omshell_egui --bin OMShell-egui
      DEPENDS rust_codegen rust_omc
      COMMENT "Rust: building OMShell-egui (${RUST_OMC_PROFILE})"
      VERBATIM)
    install(PROGRAMS ${RUST_OMC_ARTIFACT_DIR}/OMShell-egui${RUST_OMC_EXE_SUFFIX}
            DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT omc)

    # The native dioxus client uses Blitz (dioxus-native), not a webview, so the
    # Help -> WebGPU test can composite a real wgpu scene. Drop the default `web`
    # feature, select `native`. Same in-process compiler link as egui, so it also
    # DEPENDS on rust_codegen.
    add_custom_target(rust_omshell_dioxus ALL
      WORKING_DIRECTORY ${RUST_OMC_DIR}
      JOB_SERVER_AWARE TRUE
      COMMAND ${CARGO_BUILD_ARTIFACT} ${RUST_OMC_PROFILE_FLAG} ${RUST_OMC_TIMINGS_FLAG}
              -p omshell_dioxus --bin OMShell-dioxus --no-default-features --features native
      DEPENDS rust_codegen rust_omshell_egui
      COMMENT "Rust: building OMShell-dioxus (native/Blitz, ${RUST_OMC_PROFILE})"
      VERBATIM)
    install(PROGRAMS ${RUST_OMC_ARTIFACT_DIR}/OMShell-dioxus${RUST_OMC_EXE_SUFFIX}
            DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT omc)
  endif()
  install(FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/AnnotationsBuiltin_1_x.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/AnnotationsBuiltin_2_x.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/AnnotationsBuiltin_3_x.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFModelicaBuiltin.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ModelicaBuiltin.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/MetaModelicaBuiltin.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/PDEModelicaBuiltin.mo
          DESTINATION lib/omc COMPONENT omc)
  install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/scripts
          DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omc/ COMPONENT omc)
  endif() # NOT OM_OMC_WASM

  # NOTE: OpenModelicaScriptingAPI.mo is now produced by the standalone
  # scripting_api_gen tool above (rust_scripting_api target / SCRIPTING_API_MO),
  # *before* codegen, so it no longer needs a built omc and there is no bootstrap
  # cycle. The previous omc-based regeneration target has been removed.
endfunction()

# Provides, for the native CMake build of the Qt GUI clients in Rust mode, the
# OpenModelicaCompiler target they link. The OpenModelicaScriptingAPIQt sources
# OMEdit compiles are generated into OMC_SCRIPTING_API_QT_DIR by rust_codegen.
# Called whenever OM_ENABLE_GUI_CLIENTS is ON.
#
# Two modes:
#   * normal: link the cargo-built cdylib and depend on rust_libopenmodelica so it
#     is built first (the Qt sources come from rust_codegen, in this build).
#   * prebuilt (RUST_OMC_PREBUILT_CDYLIB set): link an already-built cdylib and
#     read the Qt sources from RUST_OMC_PREBUILT_SCRIPTING_API_QT_DIR, with NO
#     cargo target/dependency. Compiler/CMakeLists.txt skips the whole codegen
#     setup in this mode, so the GUI is the only thing built here. This is how a
#     split CI builds the GUI in parallel with the tests off a stage-1 cdylib.
function(omc_rust_setup_omedit)
  if(RUST_OMC_PREBUILT_CDYLIB)
    get_filename_component(_cdylib ${RUST_OMC_PREBUILT_CDYLIB} ABSOLUTE)
    # OMEditLIB reads the generated Qt API sources from OMC_SCRIPTING_API_QT_DIR;
    # in prebuilt mode rust_codegen never ran here, so point it at the stage-1 copy.
    set(OMC_SCRIPTING_API_QT_DIR ${RUST_OMC_PREBUILT_SCRIPTING_API_QT_DIR}
        CACHE INTERNAL "Generated OpenModelicaScriptingAPIQt C++ sources (prebuilt)")
  else()
    set(RUST_OMC_ARTIFACT_DIR ${RUST_TARGET_DIR}/${RUST_OMC_ARTIFACT_SUBDIR})
    set(_cdylib ${RUST_OMC_ARTIFACT_DIR}/${RUST_OMC_CDYLIB_NAME})
  endif()

  # The OpenModelicaCompiler target the Qt GUI clients link: the cargo cdylib,
  # IMPORTED GLOBAL. IMPORTED_NO_SONAME (the cdylib has none) records the basename
  # in DT_NEEDED, resolved via the client's $ORIGIN/../lib rpath. OMC_RUST_ABI
  # selects the in-process Rust path; the include dirs provide omc_rust_embedding.h
  # and the util/ header it pulls in (SimulationRuntime/c).
  get_filename_component(_simrt_c_inc ${CMAKE_CURRENT_SOURCE_DIR}/../SimulationRuntime/c ABSOLUTE)
  add_library(OpenModelicaCompiler SHARED IMPORTED GLOBAL)
  set_target_properties(OpenModelicaCompiler PROPERTIES
    IMPORTED_LOCATION ${_cdylib}
    IMPORTED_NO_SONAME TRUE
    INTERFACE_INCLUDE_DIRECTORIES "${RUST_OMC_DIR}/libopenmodelica_compiler/include;${_simrt_c_inc}"
    INTERFACE_COMPILE_DEFINITIONS OMC_RUST_ABI)
  # Windows links a DLL through its import library (cargo emits <dll>.lib).
  if(RUST_OMC_TARGET MATCHES "windows")
    set_target_properties(OpenModelicaCompiler PROPERTIES IMPORTED_IMPLIB "${_cdylib}.lib")
  endif()
  # Deps the clients inherited transitively from the C OpenModelicaCompiler but
  # which the cdylib does not carry, so propagate the targets here:
  #   * fmilib (via backendruntime), libzmq (via runtime) — 3rd-party libs.
  #   * omc::config — the omc_config.h / omc_config.unix.h include dirs (the C
  #     omcruntime/omcbackendruntime link it PUBLIC); the GUI clients angle-/
  #     quote-include omc_config.h, so without it they fail with
  #     "'omc_config.h' file not found".
  foreach(_dep fmilib omc::3rd::libzmq omc::config)
    if(TARGET ${_dep})
      set_property(TARGET OpenModelicaCompiler APPEND PROPERTY INTERFACE_LINK_LIBRARIES ${_dep})
    endif()
  endforeach()

  # Build the cdylib before any client links it. Added to the IMPORTED target,
  # it is followed transitively, so all clients inherit it without per-client
  # edits. rust_libopenmodelica is defined by omc_rust_setup_codegen, called
  # before this function.
  if(TARGET rust_libopenmodelica)
    add_dependencies(OpenModelicaCompiler rust_libopenmodelica)
  endif()
endfunction()

# ---------------------------------------------------------------------------
# Web / wasm target. The omc compiler built for wasm32-unknown-unknown plus the
# wasm-bindgen JS bindings — the browser/Node deliverable. CMake drives cargo +
# wasm-bindgen + wasm-opt directly (a first-class target with a proper dependency
# on the codegen); it does NOT shell out to wasm/build.sh.
#
# The bundle is assembled in the build tree (${CMAKE_CURRENT_BINARY_DIR}/web):
# pkg-<host>/ from wasm-bindgen plus the host's launcher (index.html for the
# browser, omc-cli.js for Node). `make install` stages that directory under
# <prefix>/<datarootdir>/omc/web (component `web`), so it can be served from a
# clean location, e.g. `python3 -m http.server -d <prefix>/share/omc/web`.
#
# Selected with -DOM_OMC_WASM=ON (top-level), which also prunes every native
# client/library the wasm bundle does not use, so `make all` builds only this.
# Called from Compiler/CMakeLists.txt in place of the native artifacts/omedit.
# ---------------------------------------------------------------------------

# Assemble one OMShell web page from an already-compiled GUI wasm, into the shared
# ${_web_dir} tree: wasm-bindgen the `_binname`.wasm into web/<crate>/ and add the
# static launcher `_srcindex` as web/<crate>.html. There is no per-page copy of
# the omc module — every page imports the single web/omc/ produced by rust_wasm
# (the launcher publishes its API on globalThis.__omc, which omc_bridge.js, bundled
# into the GUI, forwards to). So the page drives omc in-browser with no duplicated
# .wasm.
#
# The GUI crate itself is NOT compiled here: rust_wasm's single cargo invocation
# already built it alongside the compiler (see _wasm_common). This step only runs
# wasm-bindgen + assembly, so it just waits for rust_wasm, not a second cargo build.
#
# `_label` is a clean token for the cmake target name (egui/dioxus); `_binname`
# is the GUI's bin/artifact name (OMShell-egui/OMShell-dioxus), which is also the
# web dir and <name>.html so the page paths are self-consistent.
#
# Called from inside omc_rust_setup_wasm, so it reads that function's locals
# (_wasm_target, _profile, _web_dir) plus the file-scope WASM_* / RUST_* variables.
function(omc_rust_omshell_web_page _label _binname _srcindex)
  set(_gui_artifact ${RUST_TARGET_DIR}/${_wasm_target}/${_profile}/${_binname}.wasm)
  set(_gui_pkgdir ${_web_dir}/${_binname})
  set(_opt "")
  if(_profile STREQUAL "release" AND WASM_OPT_EXECUTABLE)
    set(_opt COMMAND ${WASM_OPT_EXECUTABLE} -Oz ${WASM_OPT_FEATURES}
        ${_gui_pkgdir}/${_binname}_bg.wasm -o ${_gui_pkgdir}/${_binname}_bg.wasm)
  endif()
  # rm only this page's own pkg dir (NOT ${_web_dir} — that holds the shared
  # web/omc/ and the other page). rust_wasm has already cleaned+rebuilt the tree.
  add_custom_target(rust_omshell_${_label}_web ALL
    WORKING_DIRECTORY ${RUST_OMC_DIR}
    COMMAND ${CMAKE_COMMAND} -E rm -rf ${_gui_pkgdir}
    COMMAND ${WASM_BINDGEN_EXECUTABLE} ${_gui_artifact} --out-dir ${_gui_pkgdir} --target web
    ${_opt}
    COMMAND ${CMAKE_COMMAND} -E copy ${_srcindex} ${_web_dir}/${_binname}.html
    # The omc Web Worker the GUI spawns. Shared by every page (it imports the one
    # web/omc/ module), so it lands at the web root; copying it per page is an
    # idempotent no-op for the second page.
    COMMAND ${CMAKE_COMMAND} -E copy ${RUST_OMC_DIR}/omshell_omc/omc_worker.js ${_web_dir}/omc_worker.js
    COMMENT "Rust: assembling ${_binname} web page -> ${_web_dir}/${_binname}.html"
    VERBATIM)
  # Target-level dependency on the omc module (rust_wasm), NOT its WASM_STAMP
  # file: make then builds the omc/codegen chain exactly once and orders the
  # pages after it. rust_wasm compiles this GUI (single cargo), lays down
  # web/omc/, and (re)creates ${_web_dir}; this page then adds its files. The
  # single install(DIRECTORY ${_web_dir}) in omc_rust_setup_wasm stages it all.
  add_dependencies(rust_omshell_${_label}_web rust_wasm)
endfunction()

# The FMU native-platform compiler for the browser: `openmodelica_fmi_ls_wasm_aot`
# built for wasm32-wasip1 (a compiler-only wasmtime), staged as web/fmu-aot.wasm
# and loaded on demand by wasm/fmu-aot-worker.js. Not embedded in the omc module:
# it is ~13 MB and only an export that asks for a native platform needs it.
#
# wasip1, not wasm32-unknown-unknown, because cranelift's pass timing calls
# `Instant::now()`, which panics there. Always release — a debug cranelift is far
# too slow to compile a model with.
#
# Its own `[workspace]` and target dir, so the compiler-only wasmtime never meets
# the host workspace's resolution. Reads omc_rust_setup_wasm's _web_dir.
function(omc_rust_fmu_aot_module)
  set(_aot_src ${RUST_OMC_DIR}/openmodelica_fmi_ls_wasm_aot)
  set(_aot_target_dir ${CMAKE_CURRENT_BINARY_DIR}/fmu-aot-target)
  set(_aot_artifact ${_aot_target_dir}/wasm32-wasip1/release/openmodelica_fmi_ls_wasm_aot.wasm)
  add_custom_target(rust_fmu_aot ALL
    WORKING_DIRECTORY ${_aot_src}
    JOB_SERVER_AWARE TRUE
    COMMAND ${CARGO_ENV} ${CARGO_EXECUTABLE} build --release
            --manifest-path ${_aot_src}/Cargo.toml
            --target wasm32-wasip1 --target-dir ${_aot_target_dir}
    COMMAND ${CMAKE_COMMAND} -E copy ${_aot_artifact} ${_web_dir}/fmu-aot.wasm
    COMMENT "Rust: FMU native-platform compiler (wasm32-wasip1) -> ${_web_dir}/fmu-aot.wasm"
    VERBATIM)
  # rust_wasm recreates ${_web_dir}, so the copy has to follow it.
  add_dependencies(rust_fmu_aot rust_wasm)
endfunction()

# `omplot` (openmodelica_result_cli) for wasm32-wasip1, staged as
# web/omplot/omplot.wasm next to its Node runner omplot-cli.js: the OMPlot
# module's readers, comparison and writers, runnable from a shell.
function(omc_rust_omplot_cli_module)
  set(_omplot_artifact ${RUST_TARGET_DIR}/wasm32-wasip1/release/omplot.wasm)
  add_custom_target(rust_omplot_cli ALL
    WORKING_DIRECTORY ${RUST_OMC_DIR}
    JOB_SERVER_AWARE TRUE
    COMMAND ${CARGO_ENV} ${CARGO_EXECUTABLE} build --release --target-dir ${RUST_TARGET_DIR}
            --target wasm32-wasip1 -p openmodelica_result_cli
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_web_dir}/omplot
    COMMAND ${CMAKE_COMMAND} -E copy ${_omplot_artifact} ${_web_dir}/omplot/omplot.wasm
    COMMAND ${CMAKE_COMMAND} -E copy ${RUST_OMC_DIR}/wasm/omplot/omplot-cli.js ${_web_dir}/omplot/
    COMMENT "Rust: omplot (wasm32-wasip1) -> ${_web_dir}/omplot/omplot.wasm"
    VERBATIM)
  add_dependencies(rust_omplot_cli rust_wasm)
endfunction()

# The FMI masters for the browser: `openmodelica_fmi_web` built for
# wasm32-wasip1 and staged as web/fmi-simulator/openmodelica_fmi_web.wasm, where
# the page's worker loads it. wasip1 so the result file is written through WASI
# like every other simulation's; always release, since this *is* the solver.
#
# Its own `[workspace]` and target dir, so a wasm-only cdylib never enters the
# host workspace's resolution. Reads omc_rust_setup_wasm's _web_dir.
function(omc_rust_fmi_driver_module)
  set(_fmi_src ${RUST_OMC_DIR}/openmodelica_fmi_web)
  set(_fmi_target_dir ${CMAKE_CURRENT_BINARY_DIR}/fmi-driver-target)
  set(_fmi_artifact ${_fmi_target_dir}/wasm32-wasip1/release/openmodelica_fmi_web.wasm)
  add_custom_target(rust_fmi_driver ALL
    WORKING_DIRECTORY ${_fmi_src}
    JOB_SERVER_AWARE TRUE
    COMMAND ${CARGO_ENV} ${CARGO_EXECUTABLE} build --release
            --manifest-path ${_fmi_src}/Cargo.toml
            --target wasm32-wasip1 --target-dir ${_fmi_target_dir}
    COMMAND ${CMAKE_COMMAND} -E copy ${_fmi_artifact}
            ${_web_dir}/fmi-simulator/openmodelica_fmi_web.wasm
    COMMENT "Rust: FMI masters (wasm32-wasip1) -> ${_web_dir}/fmi-simulator/openmodelica_fmi_web.wasm"
    VERBATIM)
  # rust_wasm recreates ${_web_dir}, so the copy has to follow it.
  add_dependencies(rust_fmi_driver rust_wasm)
  # `openmodelica_fmi_web/build.rs` links the wasm SUNDIALS itself, for cvode/ida.
  if(TARGET rust_hdf5_wasm)
    add_dependencies(rust_fmi_driver rust_hdf5_wasm)
  endif()
  if(TARGET rust_sundials_collect)
    add_dependencies(rust_fmi_driver rust_sundials_collect)
  endif()
endfunction()

# Assemble the Qt OMShell web page. Unlike the egui/dioxus pages (Rust crates the
# rust_wasm cargo invocation already built), this is the C++ Qt OMShell compiled
# with Qt for WebAssembly — a separate toolchain, so it is a nested cmake build
# (OMShellGUI/wasm) driven here. The result is staged in web/OMShell-qt/ next to
# the shared omc module + worker, which the page drives in-browser exactly like
# the other two. Skipped (with a status message) when no Qt-wasm toolchain is
# found, so builds without it are unaffected. Reads omc_rust_setup_wasm's locals
# (_web_dir) and the file-scope RUST_OMC_DIR.

# em++'s emsdk-bundled default cache is read-only on CI; give the nested Qt-wasm
# builds a writable one, shared across all three pages. An inherited EM_CACHE
# wins (CI points it at a persistent volume so the sysroot survives across runs).
if(DEFINED ENV{EM_CACHE})
  set(_em_cache_env "")
else()
  set(_em_cache_env ${CMAKE_COMMAND} -E env EM_CACHE=${CMAKE_CURRENT_BINARY_DIR}/emscripten-cache)
endif()

function(omc_rust_omshell_qt_web_page)
  set(OMSHELL_QT_WASM_PREFIX "/opt/Qt/6.10.2/wasm_singlethread"
      CACHE PATH "Qt-for-WebAssembly install prefix used to build the Qt OMShell web page.")
  set(_tc ${OMSHELL_QT_WASM_PREFIX}/lib/cmake/Qt6/qt.toolchain.cmake)
  if(NOT EXISTS ${_tc})
    message(STATUS "OMShell Qt web page skipped: no Qt-for-WebAssembly toolchain at "
                   "${_tc} (set -DOMSHELL_QT_WASM_PREFIX=<prefix> to enable).")
    return()
  endif()

  set(_qt_src ${CMAKE_SOURCE_DIR}/OMShell/OMShell/OMShellGUI/wasm)
  set(_qt_bld ${CMAKE_CURRENT_BINARY_DIR}/omshell-qt-wasm)
  set(_qt_pkgdir ${_web_dir}/OMShell-qt)

  # Let the wasm Qt find its matching host tools (moc/rcc/uic): honour an explicit
  # QT_HOST_PATH cache/env value, otherwise the toolchain falls back on its own.
  set(_host_arg "")
  if(QT_HOST_PATH)
    set(_host_arg -DQT_HOST_PATH=${QT_HOST_PATH})
  elseif(DEFINED ENV{QT_HOST_PATH})
    set(_host_arg -DQT_HOST_PATH=$ENV{QT_HOST_PATH})
  endif()

  add_custom_target(rust_omshell_qt_web ${_qt_web_all}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_bld}
    COMMAND ${_em_cache_env} ${CMAKE_COMMAND} -G "Unix Makefiles" -S ${_qt_src} -B ${_qt_bld}
            -DCMAKE_TOOLCHAIN_FILE=${_tc} ${_host_arg} -DCMAKE_BUILD_TYPE=Release
    COMMAND ${_em_cache_env} ${CMAKE_COMMAND} --build ${_qt_bld} --parallel
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_pkgdir}
    COMMAND ${CMAKE_COMMAND} -E copy
            ${_qt_bld}/OMShell-qt.html ${_qt_bld}/OMShell-qt.js
            ${_qt_bld}/OMShell-qt.wasm ${_qt_bld}/qtloader.js
            ${_qt_bld}/qtlogo.svg ${_qt_pkgdir}/
    COMMAND ${CMAKE_COMMAND} -E copy ${RUST_OMC_DIR}/omshell_omc/omc_worker.js ${_web_dir}/omc_worker.js
    COMMENT "Qt: building OMShell-qt web page -> ${_qt_pkgdir}"
    VERBATIM)
  if(NOT RUST_OMC_WEB_QT_STANDALONE)
    add_dependencies(rust_omshell_qt_web rust_wasm)
  endif()
endfunction()

# Assemble the Qt OMNotebook web page. Same shape as omc_rust_omshell_qt_web_page
# (nested Qt-for-WebAssembly cmake build, staged beside the shared omc module +
# worker), differing only in source dir, build dir, artifact base and package
# dir. Plotting is library-only for now (no data path from the worker VFS), so
# the page is a notebook editor that round-trips input cells through omc. Gated
# on the same OMSHELL_QT_WASM_PREFIX toolchain check and skipped with a status
# message when absent. Reads omc_rust_setup_wasm's _web_dir and file-scope
# RUST_OMC_DIR.
function(omc_rust_omnotebook_qt_web_page)
  set(OMSHELL_QT_WASM_PREFIX "/opt/Qt/6.10.2/wasm_singlethread"
      CACHE PATH "Qt-for-WebAssembly install prefix used to build the Qt OMShell web page.")
  set(_tc ${OMSHELL_QT_WASM_PREFIX}/lib/cmake/Qt6/qt.toolchain.cmake)
  if(NOT EXISTS ${_tc})
    message(STATUS "OMNotebook Qt web page skipped: no Qt-for-WebAssembly toolchain at "
                   "${_tc} (set -DOMSHELL_QT_WASM_PREFIX=<prefix> to enable).")
    return()
  endif()

  set(_qt_src ${CMAKE_SOURCE_DIR}/OMNotebook/OMNotebook/OMNotebookGUI/wasm)
  set(_qt_bld ${CMAKE_CURRENT_BINARY_DIR}/omnotebook-qt-wasm)
  set(_qt_pkgdir ${_web_dir}/OMNotebook-qt)

  set(_host_arg "")
  if(QT_HOST_PATH)
    set(_host_arg -DQT_HOST_PATH=${QT_HOST_PATH})
  elseif(DEFINED ENV{QT_HOST_PATH})
    set(_host_arg -DQT_HOST_PATH=$ENV{QT_HOST_PATH})
  endif()

  add_custom_target(rust_omnotebook_qt_web ${_qt_web_all}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_bld}
    COMMAND ${_em_cache_env} ${CMAKE_COMMAND} -G "Unix Makefiles" -S ${_qt_src} -B ${_qt_bld}
            -DCMAKE_TOOLCHAIN_FILE=${_tc} ${_host_arg} -DCMAKE_BUILD_TYPE=Release
    COMMAND ${_em_cache_env} ${CMAKE_COMMAND} --build ${_qt_bld} --parallel
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_pkgdir}
    COMMAND ${CMAKE_COMMAND} -E copy
            ${_qt_bld}/OMNotebook-qt.html ${_qt_bld}/OMNotebook-qt.js
            ${_qt_bld}/OMNotebook-qt.wasm ${_qt_bld}/qtloader.js
            ${_qt_bld}/qtlogo.svg ${_qt_pkgdir}/
    COMMAND ${CMAKE_COMMAND} -E copy ${RUST_OMC_DIR}/omshell_omc/omc_worker.js ${_web_dir}/omc_worker.js
    # Example notebooks: gzip-tar the DrModelica/DrControl trees next to the page;
    # the page fetches and extracts them into MEMFS at startup so File menus and
    # inter-notebook links resolve. All paths are < 100 chars, so the headers are
    # plain enough for the small JS tar extractor.
    COMMAND ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/OMNotebook
            ${CMAKE_COMMAND} -E tar czf ${_qt_pkgdir}/notebooks.tar.gz
            DrModelica DrControl OMNotebookHelp.onb
    COMMENT "Qt: building OMNotebook-qt web page -> ${_qt_pkgdir}"
    VERBATIM)
  if(NOT RUST_OMC_WEB_QT_STANDALONE)
    add_dependencies(rust_omnotebook_qt_web rust_wasm)
  endif()
  # Both Qt pages copy the shared omc_worker.js into ${_web_dir}; serialize them
  # so the two copies never write that file concurrently. The dependency target
  # exists whenever this one does (same toolchain gate, same build).
  add_dependencies(rust_omnotebook_qt_web rust_omshell_qt_web)
endfunction()

# Qt OMEdit web page: same shape as the OMShell/OMNotebook pages, pointed at the
# build-tree OpenModelicaScriptingAPIQt sources (OMC_SCRIPTING_API_QT_DIR).
function(omc_rust_omedit_qt_web_page)
  set(OMSHELL_QT_WASM_PREFIX "/opt/Qt/6.10.2/wasm_singlethread"
      CACHE PATH "Qt-for-WebAssembly install prefix used to build the Qt OMShell web page.")
  set(_tc ${OMSHELL_QT_WASM_PREFIX}/lib/cmake/Qt6/qt.toolchain.cmake)
  if(NOT EXISTS ${_tc})
    message(STATUS "OMEdit Qt web page skipped: no Qt-for-WebAssembly toolchain at "
                   "${_tc} (set -DOMSHELL_QT_WASM_PREFIX=<prefix> to enable).")
    return()
  endif()

  set(_qt_src ${CMAKE_SOURCE_DIR}/OMEdit/OMEditGUI/wasm)
  set(_qt_bld ${CMAKE_CURRENT_BINARY_DIR}/omedit-qt-wasm)
  set(_qt_pkgdir ${_web_dir}/OMEdit-qt)

  # QT_HOST_PATH for the cross Qt toolchain; fall back to the wasm prefix's
  # sibling gcc_64 so a first-time configure needs no cache/env value.
  set(_host_arg "")
  if(QT_HOST_PATH)
    set(_host_arg -DQT_HOST_PATH=${QT_HOST_PATH})
  elseif(DEFINED ENV{QT_HOST_PATH})
    set(_host_arg -DQT_HOST_PATH=$ENV{QT_HOST_PATH})
  else()
    get_filename_component(_qt_base ${OMSHELL_QT_WASM_PREFIX} DIRECTORY)
    if(EXISTS ${_qt_base}/gcc_64/lib/cmake/Qt6)
      set(_host_arg -DQT_HOST_PATH=${_qt_base}/gcc_64)
    endif()
  endif()

  add_custom_target(rust_omedit_qt_web ${_qt_web_all}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_bld}
    COMMAND ${_em_cache_env} ${CMAKE_COMMAND} -G "Unix Makefiles" -S ${_qt_src} -B ${_qt_bld}
            -DCMAKE_TOOLCHAIN_FILE=${_tc} ${_host_arg} -DCMAKE_BUILD_TYPE=Release
            -DOMEDIT_WASM_OPTIMIZE=${OMEDIT_WASM_OPTIMIZE}
            -DSCRIPTING_API_QT_DIR=${OMC_SCRIPTING_API_QT_DIR}
    COMMAND ${_em_cache_env} ${CMAKE_COMMAND} --build ${_qt_bld} --parallel
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_pkgdir}
    COMMAND ${CMAKE_COMMAND} -E copy
            ${_qt_bld}/OMEdit-qt.html ${_qt_bld}/OMEdit-qt.js
            ${_qt_bld}/OMEdit-qt.wasm ${_qt_bld}/qtloader.js
            ${_qt_bld}/qtlogo.svg ${_qt_pkgdir}/
    COMMAND ${CMAKE_COMMAND} -E copy ${RUST_OMC_DIR}/omshell_omc/omc_worker.js ${_web_dir}/omc_worker.js
    COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_SOURCE_DIR}/OMEdit/OMEditLIB/Resources/icons/omedit_splashscreen.png ${_qt_pkgdir}/
    COMMENT "Qt: building OMEdit-qt web page -> ${_qt_pkgdir}"
    VERBATIM)
  if(NOT RUST_OMC_WEB_QT_STANDALONE)
    add_dependencies(rust_omedit_qt_web rust_wasm)
  endif()
  # Serialise the shared omc_worker.js copy with the other Qt pages.
  if(TARGET rust_omshell_qt_web)
    add_dependencies(rust_omedit_qt_web rust_omshell_qt_web)
  endif()
endfunction()

function(omc_rust_setup_wasm)
  # RUST_OMC_WASM_MODE = <host>-<profile>: host selects the wasm-bindgen target
  # (nodejs / web), profile the cargo profile.
  set(RUST_OMC_WASM_MODE "web-release"
      CACHE STRING "wasm build mode: node-debug, node-release, web-debug or web-release.")
  set_property(CACHE RUST_OMC_WASM_MODE PROPERTY STRINGS
               node-debug node-release web-debug web-release)
  if(RUST_OMC_WASM_MODE STREQUAL "node-debug")
    set(_host nodejs)
    set(_profile debug)
  elseif(RUST_OMC_WASM_MODE STREQUAL "node-release")
    set(_host nodejs)
    set(_profile release)
  elseif(RUST_OMC_WASM_MODE STREQUAL "web-debug")
    set(_host web)
    set(_profile debug)
  elseif(RUST_OMC_WASM_MODE STREQUAL "web-release")
    set(_host web)
    set(_profile release)
  else()
    message(FATAL_ERROR "RUST_OMC_WASM_MODE must be one of "
                        "node-debug|node-release|web-debug|web-release, got "
                        "'${RUST_OMC_WASM_MODE}'.")
  endif()

  # wasm-bindgen-cli is mandatory for this target; the wasm32 rustup target must
  # also be installed. REQUIRED → a clear configure error instead of a cryptic
  # mid-build failure. (WASM_OPT_EXECUTABLE is found at file scope and reused
  # here; it is optional, only shrinking the release bundle.)
  find_program(WASM_BINDGEN_EXECUTABLE wasm-bindgen REQUIRED
               HINTS $ENV{CARGO_HOME}/bin $ENV{HOME}/.cargo/bin)

  set(_wasm_target wasm32-unknown-unknown)
  set(_wasm_name OpenModelicaCompiler)
  # wasmtime has no wasm backend, so the wasm-jit engine must be wasmer (`js`);
  # the cdylib is built with no default features (drops the native-only deps).
  # `codegen_fmu` is on for the wasm FMU export's modelDescription.xml: the
  # description templates only, not `codegen_fmu_c`/`codegen_c` -- the wasm-jit
  # target emits the model itself.
  #
  # When the OMShell web pages are wanted (GUI clients on, browser host) their
  # crates are added to this *same* cargo invocation, so eframe/dioxus and their
  # deps compile in parallel with the compiler rather than serially after it.
  # --no-default-features then applies to all selected packages, so the features
  # are package-qualified (omshell_egui has none; omshell_dioxus needs `web`).
  set(_build_omshell_web FALSE)
  if(OM_ENABLE_GUI_CLIENTS AND _host STREQUAL "web")
    set(_build_omshell_web TRUE)
  endif()
  # scripting_api gives the worker omc_abi (the OMEdit typed ABI dispatcher).
  # RUST_OMC_SCRIPTING_API defaults to OM_ENABLE_GUI_CLIENTS, which also selects
  # the OMEdit page, so the two stay in sync.
  set(_wasm_scripting_feature "")
  if(RUST_OMC_SCRIPTING_API)
    set(_wasm_scripting_feature ",libopenmodelica_compiler/scripting_api")
  endif()
  # Forward the sundials feature for the wasm-jit runtime (KLU sparse solver).
  set(_wasm_sundials_feature "")
  if(RUST_OMC_ENABLE_SUNDIALS)
    set(_wasm_sundials_feature ",openmodelica_codegen_wasm_jit/sundials")
  endif()
  # Standalone wasm modules for the browser pages, built in the same cargo pass
  # (features package-qualified so the extra -p stays unambiguous).
  set(_anim_pkg "")
  if(_host STREQUAL "web")
    set(_anim_pkg -p openmodelica_animation_wasm -p openmodelica_result_web)
  endif()
  if(_build_omshell_web)
    set(_wasm_common --target ${_wasm_target}
                     -p libopenmodelica_compiler -p omshell_egui -p omshell_dioxus ${_anim_pkg}
                     --no-default-features
                     --features libopenmodelica_compiler/engine-wasmer,libopenmodelica_compiler/codegen_fmu,omshell_dioxus/web${_wasm_scripting_feature}${_wasm_sundials_feature})
  else()
    set(_wasm_common --target ${_wasm_target} -p libopenmodelica_compiler ${_anim_pkg}
                     --no-default-features
                     --features libopenmodelica_compiler/engine-wasmer,libopenmodelica_compiler/codegen_fmu${_wasm_scripting_feature}${_wasm_sundials_feature})
  endif()

  if(_profile STREQUAL "release")
    set(_cargo_profile_flag --release)
    set(_cargo_backend "")
  else()
    set(_cargo_profile_flag "")
    # The workspace dev profile uses the cranelift *rustc* backend (fast native
    # builds); it cannot target wasm32, so force the LLVM backend for codegen.
    set(_cargo_backend --config profile.dev.codegen-backend=\"llvm\")
  endif()

  set(_wasm_artifact ${RUST_TARGET_DIR}/${_wasm_target}/${_profile}/${_wasm_name}.wasm)
  # Assemble the runnable bundle in the build tree (never the source tree). The
  # whole ${_web_dir} is installed as one tree, so this *is* the served layout:
  #   web/index.html            + web/omc/*           (the client launcher + shared omc module)
  #   web/home/index.html                             (default client: getVersion() splash)
  #   web/omc-terminal/index.html                     (the omc REPL, one OMShell variant)
  #   web/omshell_egui.html      + web/omshell_egui/*   (added by the page helper)
  #   web/omshell_dioxus.html    + web/omshell_dioxus/*
  # index.html is an SPA that loads each client in an iframe (hash-routed for
  # shareable links). The browser launcher imports ./omc/; Node keeps
  # pkg-nodejs/ + omc-cli.js.
  set(_web_dir ${CMAKE_CURRENT_BINARY_DIR}/web)
  set(_web_launcher_extra "")
  if(_host STREQUAL "web")
    set(_wasm_pkgdir ${_web_dir}/omc)
    set(_web_launcher ${RUST_OMC_DIR}/wasm/index.html)

    # three.js is large minified vendor code, not kept in git. Download and cache
    # it at configure time, pinned to r169 (matching the vendored OrbitControls.js)
    # with an integrity hash. Cached in the build tree; re-download only if absent.
    set(_three_js ${CMAKE_BINARY_DIR}/downloads/three.module.min.js)
    if(NOT EXISTS ${_three_js})
      message(STATUS "Downloading three.module.min.js (r169)…")
      file(DOWNLOAD
           https://unpkg.com/three@0.169.0/build/three.module.min.js ${_three_js}
           EXPECTED_HASH SHA256=f7cee3c7533449a1505cc12cb5128b89e3d4fd3d7ea62b05f9f5464a217472ee
           TLS_VERIFY ON STATUS _three_dl)
      list(GET _three_dl 0 _three_dl_code)
      if(NOT _three_dl_code EQUAL 0)
        file(REMOVE ${_three_js})
        message(FATAL_ERROR "Failed to download three.module.min.js: ${_three_dl}")
      endif()
    endif()

    # The FMI simulator transpiles a Wasm component to JS in the browser using
    # jco's js-component-bindgen, which runs on the WASI preview2 shim. Both are
    # vendor code, not kept in git: download the pinned npm tarballs at configure
    # time and unpack them into the build tree.
    set(_jco_vendor ${CMAKE_BINARY_DIR}/downloads/jco-transpile/package/vendor)
    set(_p2_shim ${CMAKE_BINARY_DIR}/downloads/preview2-shim/package/dist/browser)
    foreach(_pkg IN ITEMS
            "jco-transpile|0.4.2|6f65610ecef99501084de896e299885fc6f645ee77413a820c20aa3d53f21bc7"
            "preview2-shim|0.19.0|625d787a571bb1dd4b4e1d0fe51e2ef2f0b24e689d7cfcaff6c47ee866dc3526")
      string(REPLACE "|" ";" _p ${_pkg})
      list(GET _p 0 _p_name)
      list(GET _p 1 _p_ver)
      list(GET _p 2 _p_hash)
      set(_p_dir ${CMAKE_BINARY_DIR}/downloads/${_p_name})
      if(NOT EXISTS ${_p_dir}/package/package.json)
        set(_p_tgz ${CMAKE_BINARY_DIR}/downloads/${_p_name}-${_p_ver}.tgz)
        message(STATUS "Downloading @bytecodealliance/${_p_name} ${_p_ver}…")
        file(DOWNLOAD
             https://registry.npmjs.org/@bytecodealliance/${_p_name}/-/${_p_name}-${_p_ver}.tgz
             ${_p_tgz} EXPECTED_HASH SHA256=${_p_hash} TLS_VERIFY ON STATUS _p_dl)
        list(GET _p_dl 0 _p_dl_code)
        if(NOT _p_dl_code EQUAL 0)
          file(REMOVE ${_p_tgz})
          message(FATAL_ERROR "Failed to download @bytecodealliance/${_p_name}: ${_p_dl}")
        endif()
        # cmake -E tar, not file(ARCHIVE_EXTRACT): that needs 3.18, and the web
        # target should not raise the repo's CMake floor.
        file(MAKE_DIRECTORY ${_p_dir})
        execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${_p_tgz}
                        WORKING_DIRECTORY ${_p_dir} RESULT_VARIABLE _p_untar)
        if(NOT _p_untar EQUAL 0)
          file(REMOVE_RECURSE ${_p_tgz} ${_p_dir})
          message(FATAL_ERROR "Failed to unpack ${_p_tgz}: ${_p_untar}")
        endif()
      endif()
    endforeach()

    # Static page sources copied into the bundle. Listed as DEPENDS below so an
    # edit to any of them re-assembles the bundle (the wasm itself need not change).
    set(_web_launcher_deps
        ${RUST_OMC_DIR}/wasm/omc-terminal/index.html
        ${RUST_OMC_DIR}/wasm/home/index.html
        ${RUST_OMC_DIR}/wasm/simulator/index.html
        ${RUST_OMC_DIR}/wasm/simulator/omc-worker.js
        ${RUST_OMC_DIR}/wasm/simulator/config.json
        ${RUST_OMC_DIR}/wasm/simulator/examples/BouncingBall.mo
        ${RUST_OMC_DIR}/wasm/simulator/examples/DistrictHeating.mo
        ${RUST_OMC_DIR}/wasm/plot.js
        ${RUST_OMC_DIR}/wasm/units.js
        ${RUST_OMC_DIR}/wasm/theme.css
        ${RUST_OMC_DIR}/wasm/ui.js
        ${RUST_OMC_DIR}/wasm/fmu-aot.js
        ${RUST_OMC_DIR}/wasm/fmu-aot-worker.js
        # Shared 3D animation view (anim/), used by both simulator pages.
        ${RUST_OMC_DIR}/wasm/anim/animation.js
        ${RUST_OMC_DIR}/wasm/anim/OrbitControls.js
        ${RUST_OMC_DIR}/wasm/anim/anim-view.js
        ${RUST_OMC_DIR}/wasm/anim/anim-core.js
        ${RUST_OMC_DIR}/openmodelica_animation_wasm/src/lib.rs
        ${RUST_OMC_DIR}/openmodelica_animation_wasm/Cargo.toml
        ${RUST_OMC_DIR}/wasm/omplot/index.html
        ${RUST_OMC_DIR}/openmodelica_result_web/src/lib.rs
        ${RUST_OMC_DIR}/openmodelica_result_web/Cargo.toml
        ${RUST_OMC_DIR}/wasm/fmi-simulator/index.html
        ${RUST_OMC_DIR}/wasm/fmi-simulator/fmu.js
        ${RUST_OMC_DIR}/wasm/fmi-simulator/fmu-core.js
        ${RUST_OMC_DIR}/wasm/fmi-simulator/driver.js
        ${RUST_OMC_DIR}/wasm/fmi-simulator/session.js
        ${RUST_OMC_DIR}/wasm/fmi-simulator/fmi-worker.js
        ${RUST_OMC_DIR}/wasm/fmi-simulator/wasi.js
        ${RUST_OMC_DIR}/wasm/fmi-simulator/selftest.html
        ${_three_js})
    set(_web_launcher_extra
        # The chart engine and the shared look, imported by both simulator pages.
        COMMAND ${CMAKE_COMMAND} -E make_directory ${_web_dir}
        COMMAND ${CMAKE_COMMAND} -E copy
                ${RUST_OMC_DIR}/wasm/plot.js
                ${RUST_OMC_DIR}/wasm/units.js
                ${RUST_OMC_DIR}/wasm/theme.css
                ${RUST_OMC_DIR}/wasm/ui.js
                ${RUST_OMC_DIR}/wasm/fmu-aot.js
                ${RUST_OMC_DIR}/wasm/fmu-aot-worker.js
                ${_web_dir}/
        COMMAND ${CMAKE_COMMAND} -E make_directory ${_web_dir}/omc-terminal
        COMMAND ${CMAKE_COMMAND} -E copy
                ${RUST_OMC_DIR}/wasm/omc-terminal/index.html ${_web_dir}/omc-terminal/
        COMMAND ${CMAKE_COMMAND} -E make_directory ${_web_dir}/home
        COMMAND ${CMAKE_COMMAND} -E copy
                ${RUST_OMC_DIR}/wasm/home/index.html ${_web_dir}/home/
        COMMAND ${CMAKE_COMMAND} -E make_directory ${_web_dir}/simulator
        COMMAND ${CMAKE_COMMAND} -E copy
                ${RUST_OMC_DIR}/wasm/simulator/index.html
                ${RUST_OMC_DIR}/wasm/simulator/omc-worker.js
                ${RUST_OMC_DIR}/wasm/simulator/config.json
                ${_web_dir}/simulator/
        COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${RUST_OMC_DIR}/wasm/simulator/examples ${_web_dir}/simulator/examples
        # Shared anim/ module: the wasm-bindgen'd anim wasm plus the renderer/panel
        # JS and three.js, imported by both simulator pages as ../anim/*.
        COMMAND ${CMAKE_COMMAND} -E make_directory ${_web_dir}/anim
        COMMAND ${WASM_BINDGEN_EXECUTABLE}
                ${RUST_TARGET_DIR}/${_wasm_target}/${_profile}/openmodelica_animation_wasm.wasm
                --out-dir ${_web_dir}/anim --target web
        COMMAND ${CMAKE_COMMAND} -E copy
                ${RUST_OMC_DIR}/wasm/anim/animation.js
                ${RUST_OMC_DIR}/wasm/anim/OrbitControls.js
                ${RUST_OMC_DIR}/wasm/anim/anim-view.js
                ${RUST_OMC_DIR}/wasm/anim/anim-core.js
                ${_three_js} ${_web_dir}/anim/
        # OMPlot: the page plus its wasm-bindgen'd result-file module.
        COMMAND ${CMAKE_COMMAND} -E make_directory ${_web_dir}/omplot
        COMMAND ${WASM_BINDGEN_EXECUTABLE}
                ${RUST_TARGET_DIR}/${_wasm_target}/${_profile}/openmodelica_result_web.wasm
                --out-dir ${_web_dir}/omplot --target web
        COMMAND ${CMAKE_COMMAND} -E copy ${RUST_OMC_DIR}/wasm/omplot/index.html ${_web_dir}/omplot/
        COMMAND ${CMAKE_COMMAND} -E make_directory ${_web_dir}/fmi-simulator/vendor
        COMMAND ${CMAKE_COMMAND} -E copy
                ${RUST_OMC_DIR}/wasm/fmi-simulator/index.html
                ${RUST_OMC_DIR}/wasm/fmi-simulator/fmu.js
                ${RUST_OMC_DIR}/wasm/fmi-simulator/fmu-core.js
                ${RUST_OMC_DIR}/wasm/fmi-simulator/driver.js
                ${RUST_OMC_DIR}/wasm/fmi-simulator/session.js
                ${RUST_OMC_DIR}/wasm/fmi-simulator/fmi-worker.js
                ${RUST_OMC_DIR}/wasm/fmi-simulator/wasi.js
                ${RUST_OMC_DIR}/wasm/fmi-simulator/selftest.html
                ${_web_dir}/fmi-simulator/
        COMMAND ${CMAKE_COMMAND} -E copy
                ${_jco_vendor}/js-component-bindgen-component.js
                ${_jco_vendor}/js-component-bindgen-component.core.wasm
                ${_jco_vendor}/js-component-bindgen-component.core2.wasm
                ${_web_dir}/fmi-simulator/vendor/
        COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${_p2_shim} ${_web_dir}/fmi-simulator/vendor/preview2-shim
        COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${RUST_OMC_DIR}/wasm/icons ${_web_dir}/icons)
  else()
    set(_wasm_pkgdir ${_web_dir}/pkg-nodejs)
    set(_web_launcher ${RUST_OMC_DIR}/wasm/omc-cli.js)
    set(_web_launcher_deps "")
  endif()

  # Release size optimisation, only if binaryen is available.
  set(_wasm_opt_cmd "")
  if(_profile STREQUAL "release" AND WASM_OPT_EXECUTABLE)
    set(_wasm_opt_cmd COMMAND ${WASM_OPT_EXECUTABLE} -Oz ${WASM_OPT_FEATURES}
        ${_wasm_pkgdir}/${_wasm_name}_bg.wasm -o ${_wasm_pkgdir}/${_wasm_name}_bg.wasm)
  endif()

  # Cargo invocation. If a prebuilt runtime.wasm was supplied (CI stage 2),
  # forward it as OMC_WASM_RUNTIME so the wasm-jit build.rs embeds it instead of
  # rebuilding it. Built from CARGO_ENV (incremental setting) like CARGO_BUILD.
  set(_wasm_cargo ${CARGO_ENV})
  if(RUST_OMC_WASM_RUNTIME)
    list(APPEND _wasm_cargo OMC_WASM_RUNTIME=${RUST_OMC_WASM_RUNTIME})
  endif()
  list(APPEND _wasm_cargo ${CARGO_EXECUTABLE} build --target-dir ${RUST_TARGET_DIR})

  # Always run cargo (incremental, so a no-op when nothing changed) to pick up
  # hand-written crate edits. The expensive wasm-bindgen + wasm-opt only re-run
  # when the cargo .wasm actually changed: the bundle command's output depends on
  # ${_wasm_artifact}, which cargo leaves untouched on a no-op build.
  add_custom_target(rust_wasm_cargo ALL
    WORKING_DIRECTORY ${RUST_OMC_DIR}
    JOB_SERVER_AWARE TRUE
    COMMAND ${_wasm_cargo} ${_cargo_profile_flag} ${RUST_OMC_TIMINGS_FLAG} ${_wasm_common} ${_cargo_backend}
    BYPRODUCTS ${_wasm_artifact}
    DEPENDS rust_codegen rust_wasi_pic_sysroot
    COMMENT "Rust: cargo build wasm/web (${RUST_OMC_WASM_MODE})"
    VERBATIM)
  add_dependencies(rust_wasm_cargo rust_src_sync)
  if(RUST_OMC_ENABLE_SUNDIALS)
    add_dependencies(rust_wasm_cargo rust_sundials_collect)
  endif()
  if(RUST_OMC_ENABLE_HDF5)
    add_dependencies(rust_wasm_cargo rust_hdf5_wasm)
  endif()
  add_custom_command(
    OUTPUT ${_wasm_pkgdir}/${_wasm_name}_bg.wasm
    COMMAND ${CMAKE_COMMAND} -E rm -rf ${_web_dir}
    COMMAND ${WASM_BINDGEN_EXECUTABLE} ${_wasm_artifact}
            --out-dir ${_wasm_pkgdir} --target ${_host}
    ${_wasm_opt_cmd}
    COMMAND ${CMAKE_COMMAND} -E copy ${_web_launcher} ${_web_dir}/
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${RUST_FMU_LOADERS_DIR} ${_web_dir}/fmu-loaders
    ${_web_launcher_extra}
    DEPENDS ${_wasm_artifact} rust_wasm_cargo ${_web_launcher} ${_web_launcher_deps}
    COMMENT "Rust: wasm-bindgen + wasm-opt -> ${_web_dir}"
    VERBATIM)
  add_custom_target(rust_wasm ALL DEPENDS ${_wasm_pkgdir}/${_wasm_name}_bg.wasm)

  # make install: stage the whole assembled tree (omc module + launcher, plus any
  # OMShell pages added below) in one runnable location. The trailing slash
  # installs the directory's *contents*. The omc module is installed once (web/omc)
  # and shared by every page, so the .wasm is not duplicated.
  install(DIRECTORY ${_web_dir}/
          DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omc/web
          COMPONENT web)

  # OMShell web GUIs (egui + dioxus): in the wasm build the GUI-clients flag
  # (OM_ENABLE_GUI_CLIENTS, the Qt clients being unavailable here) selects the
  # OMShell web pages instead. Each is assembled next to a copy of the omc module
  # above so the page drives omc in-browser, and installed to
  # <datarootdir>/omc/web-omshell-<gui>/. A Node host has no DOM, so the pages are
  # built only for the browser host.
  if(_host STREQUAL "web")
    omc_rust_fmu_aot_module()
    omc_rust_fmi_driver_module()
    omc_rust_omplot_cli_module()
  endif()

  if(OM_ENABLE_GUI_CLIENTS)
    if(_host STREQUAL "web")
      omc_rust_omshell_web_page(egui   OMShell-egui   ${RUST_OMC_DIR}/omshell_egui/web/index.html)
      omc_rust_omshell_web_page(dioxus OMShell-dioxus ${RUST_OMC_DIR}/omshell_dioxus/web/index.html)
      if(RUST_OMC_WEB_QT OR RUST_OMC_WEB_QT_STANDALONE)
        omc_rust_omshell_qt_web_page()
        omc_rust_omnotebook_qt_web_page()
        omc_rust_omedit_qt_web_page()
      endif()
    else()
      message(STATUS "OMShell web pages skipped: RUST_OMC_WASM_MODE is a Node host "
                     "(set web-release/web-debug to build them).")
    endif()
  endif()
endfunction()
