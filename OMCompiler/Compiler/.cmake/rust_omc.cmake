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
# Not cached: a normal set() shadows a stale cache from before this was per-build,
# so reconfiguring an existing build dir picks up the new path.
set(RUST_OMC_DIR ${CMAKE_CURRENT_BINARY_DIR}/rust-src)
set(RUST_SRC_MANIFEST ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/rust_src_files.txt)

# Mirror now so the configure-time reads below (.gitignore, susanSources.txt) see
# a populated copy; the rust_src_sync target re-mirrors before each build step.
set(_rust_src_sync_cmd ${CMAKE_COMMAND}
    -DSRC=${RUST_OMC_SRC_DIR} -DDST=${RUST_OMC_DIR} -DMANIFEST=${RUST_SRC_MANIFEST}
    -P ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/rust_src_sync.cmake)
execute_process(COMMAND ${_rust_src_sync_cmd} RESULT_VARIABLE _rust_src_sync_rc)
if(_rust_src_sync_rc)
  message(FATAL_ERROR "Initial Rust source mirror failed (${RUST_OMC_SRC_DIR} -> ${RUST_OMC_DIR}).")
endif()
add_custom_target(rust_src_sync
  COMMAND ${_rust_src_sync_cmd}
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

# cargo target/ lives in the build tree, not the source crate tree.
set(RUST_OMC_TARGET_DIR ${CMAKE_CURRENT_BINARY_DIR}/rust-target
    CACHE PATH "Directory for cargo's target/ output of the Rust omc build.")
set(RUST_TARGET_DIR ${RUST_OMC_TARGET_DIR})
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
#     omc_Error_getCurrentComponent. The Jenkins image installs a current mold
#     (.CI/cache/rust/Dockerfile); when OFF the fallback is the toolchain default
#     (rust's bundled lld, itself a fast linker that supports the flag).
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
list(APPEND CARGO_ENV
     "OMC_RT_LDFLAGS_GENERATED_CODE=${RT_LDFLAGS_GENERATED_CODE}"
     "OMC_RT_LDFLAGS_GENERATED_CODE_SIM=${RT_LDFLAGS_GENERATED_CODE_SIM}"
     "OMC_RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU=${RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU}"
     "OMC_RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC=${RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC}")
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
# ---------------------------------------------------------------------------
add_test(NAME rust_cargo_test
  COMMAND ${CARGO_ENV} ${CARGO_EXECUTABLE} test --target-dir ${RUST_TARGET_DIR} --workspace
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
# wasm-opt is found here (optional) and reused by the web target below.
# ---------------------------------------------------------------------------
find_program(WASM_OPT_EXECUTABLE wasm-opt
             HINTS $ENV{CARGO_HOME}/bin $ENV{HOME}/.cargo/bin)
# wasm-opt feature flags, shared by every wasm-opt invocation below. rustc/LLVM
# emit wasm32-unknown-unknown with these post-MVP features on, but the release
# `strip` drops the target_features custom section binaryen would auto-detect
# from — so it defaults to MVP and rejects the bulk-memory/sign-ext/etc. ops.
# Enable exactly the set rustc reports (`rustc --print cfg --target
# wasm32-unknown-unknown`); blindly enabling all features could let wasm-opt emit
# instructions the JIT/browser consumers don't support.
set(WASM_OPT_FEATURES
    --enable-bulk-memory --enable-multivalue --enable-mutable-globals
    --enable-nontrapping-float-to-int --enable-reference-types --enable-sign-ext)
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
# the command always runs but is a fast no-op when nothing changed.
# ---------------------------------------------------------------------------
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
  foreach(_f ${OMC_MM_ALWAYS_SOURCES} ${OMC_MM_BACKEND_SOURCES})
    # Redirect the in-source Util/Autoconf.mo to the build-tree copy (see
    # RUST_AUTOCONF_MO above); it isn't generated into Compiler/Util in Rust mode.
    if(_f MATCHES "Util/Autoconf\\.mo$")
      string(APPEND _rust_src_content "${RUST_AUTOCONF_MO}\n")
    else()
      string(APPEND _rust_src_content "${_f}\n")
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
  # target is always present and is not a feature). codegen_fmu implies
  # codegen_c in the crate's feature table.
  set(_rust_omc_features codegen_c codegen_fmu)
  if(OM_OMC_ENABLE_CPP_RUNTIME)
    list(APPEND _rust_omc_features cpp)
  endif()
  if(RUST_OMC_SCRIPTING_API)
    list(APPEND _rust_omc_features scripting_api)
  endif()
  # Force the pure-Rust nalgebra LAPACK fallback over the system-LAPACK FFI on a
  # native build, to validate it against the testsuite. openmodelica_util is a
  # direct dependency of the cdylib, so its feature can be enabled by the
  # `<dep>/<feature>` form. (wasm and Windows select it unconditionally already.)
  option(RUST_OMC_LAPACK_NALGEBRA "Build the native omc with the pure-Rust nalgebra LAPACK fallback instead of system LAPACK (for testsuite validation)." OFF)
  if(RUST_OMC_LAPACK_NALGEBRA)
    list(APPEND _rust_omc_features openmodelica_util/lapack-nalgebra)
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
    DEPENDS rust_codegen
    COMMENT "Rust: building ${RUST_OMC_CDYLIB_NAME} (${RUST_OMC_PROFILE})"
    VERBATIM)

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

  # The native egui OMShell client (omshell_egui), built when the GUI clients are
  # enabled (OM_ENABLE_GUI_CLIENTS, the same flag that drives OMEdit). It links the
  # compiler in-process as an ordinary cargo dependency (omshell_omc ->
  # openmodelica_backend_main), so building it compiles the compiler crates too;
  # hence the DEPENDS on rust_codegen (the generated sources must exist first).
  # The browser build of OMShell is handled by the wasm target (also gated on
  # OM_ENABLE_GUI_CLIENTS).
  if(OM_ENABLE_GUI_CLIENTS)
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

# Assemble the Qt OMShell web page. Unlike the egui/dioxus pages (Rust crates the
# rust_wasm cargo invocation already built), this is the C++ Qt OMShell compiled
# with Qt for WebAssembly — a separate toolchain, so it is a nested cmake build
# (OMShellGUI/wasm) driven here. The result is staged in web/OMShell-qt/ next to
# the shared omc module + worker, which the page drives in-browser exactly like
# the other two. Skipped (with a status message) when no Qt-wasm toolchain is
# found, so builds without it are unaffected. Reads omc_rust_setup_wasm's locals
# (_web_dir) and the file-scope RUST_OMC_DIR.
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

  add_custom_target(rust_omshell_qt_web ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_bld}
    COMMAND ${CMAKE_COMMAND} -G "Unix Makefiles" -S ${_qt_src} -B ${_qt_bld}
            -DCMAKE_TOOLCHAIN_FILE=${_tc} ${_host_arg} -DCMAKE_BUILD_TYPE=Release
    COMMAND ${CMAKE_COMMAND} --build ${_qt_bld} --parallel
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_pkgdir}
    COMMAND ${CMAKE_COMMAND} -E copy
            ${_qt_bld}/OMShell-qt.html ${_qt_bld}/OMShell-qt.js
            ${_qt_bld}/OMShell-qt.wasm ${_qt_bld}/qtloader.js ${_qt_pkgdir}/
    COMMAND ${CMAKE_COMMAND} -E copy ${RUST_OMC_DIR}/omshell_omc/omc_worker.js ${_web_dir}/omc_worker.js
    COMMENT "Qt: building OMShell-qt web page -> ${_qt_pkgdir}"
    VERBATIM)
  add_dependencies(rust_omshell_qt_web rust_wasm)
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

  add_custom_target(rust_omnotebook_qt_web ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_bld}
    COMMAND ${CMAKE_COMMAND} -G "Unix Makefiles" -S ${_qt_src} -B ${_qt_bld}
            -DCMAKE_TOOLCHAIN_FILE=${_tc} ${_host_arg} -DCMAKE_BUILD_TYPE=Release
    COMMAND ${CMAKE_COMMAND} --build ${_qt_bld} --parallel
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_pkgdir}
    COMMAND ${CMAKE_COMMAND} -E copy
            ${_qt_bld}/OMNotebook-qt.html ${_qt_bld}/OMNotebook-qt.js
            ${_qt_bld}/OMNotebook-qt.wasm ${_qt_bld}/qtloader.js ${_qt_pkgdir}/
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
  add_dependencies(rust_omnotebook_qt_web rust_wasm)
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

  add_custom_target(rust_omedit_qt_web ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_bld}
    COMMAND ${CMAKE_COMMAND} -G "Unix Makefiles" -S ${_qt_src} -B ${_qt_bld}
            -DCMAKE_TOOLCHAIN_FILE=${_tc} ${_host_arg} -DCMAKE_BUILD_TYPE=Release
            -DSCRIPTING_API_QT_DIR=${OMC_SCRIPTING_API_QT_DIR}
    COMMAND ${CMAKE_COMMAND} --build ${_qt_bld} --parallel
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_qt_pkgdir}
    COMMAND ${CMAKE_COMMAND} -E copy
            ${_qt_bld}/OMEdit-qt.html ${_qt_bld}/OMEdit-qt.js
            ${_qt_bld}/OMEdit-qt.wasm ${_qt_bld}/qtloader.js ${_qt_pkgdir}/
    COMMAND ${CMAKE_COMMAND} -E copy ${RUST_OMC_DIR}/omshell_omc/omc_worker.js ${_web_dir}/omc_worker.js
    COMMENT "Qt: building OMEdit-qt web page -> ${_qt_pkgdir}"
    VERBATIM)
  add_dependencies(rust_omedit_qt_web rust_wasm)
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
  if(_build_omshell_web)
    set(_wasm_common --target ${_wasm_target}
                     -p libopenmodelica_compiler -p omshell_egui -p omshell_dioxus
                     --no-default-features
                     --features libopenmodelica_compiler/engine-wasmer,omshell_dioxus/web${_wasm_scripting_feature})
  else()
    set(_wasm_common --target ${_wasm_target} -p libopenmodelica_compiler
                     --no-default-features --features engine-wasmer${_wasm_scripting_feature})
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
  #   web/index.html            + web/omc/*           (the omc module — shared)
  #   web/omshell_egui.html      + web/omshell_egui/*   (added by the page helper)
  #   web/omshell_dioxus.html    + web/omshell_dioxus/*
  # The browser launcher imports ./omc/; Node keeps pkg-nodejs/ + omc-cli.js.
  set(_web_dir ${CMAKE_CURRENT_BINARY_DIR}/web)
  if(_host STREQUAL "web")
    set(_wasm_pkgdir ${_web_dir}/omc)
    set(_web_launcher ${RUST_OMC_DIR}/wasm/index.html)
  else()
    set(_wasm_pkgdir ${_web_dir}/pkg-nodejs)
    set(_web_launcher ${RUST_OMC_DIR}/wasm/omc-cli.js)
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
    DEPENDS rust_codegen
    COMMENT "Rust: cargo build wasm/web (${RUST_OMC_WASM_MODE})"
    VERBATIM)
  add_dependencies(rust_wasm_cargo rust_src_sync)
  add_custom_command(
    OUTPUT ${_wasm_pkgdir}/${_wasm_name}_bg.wasm
    COMMAND ${CMAKE_COMMAND} -E rm -rf ${_web_dir}
    COMMAND ${WASM_BINDGEN_EXECUTABLE} ${_wasm_artifact}
            --out-dir ${_wasm_pkgdir} --target ${_host}
    ${_wasm_opt_cmd}
    COMMAND ${CMAKE_COMMAND} -E copy ${_web_launcher} ${_web_dir}/
    DEPENDS ${_wasm_artifact} rust_wasm_cargo
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
  if(OM_ENABLE_GUI_CLIENTS)
    if(_host STREQUAL "web")
      omc_rust_omshell_web_page(egui   OMShell-egui   ${RUST_OMC_DIR}/omshell_egui/web/index.html)
      omc_rust_omshell_web_page(dioxus OMShell-dioxus ${RUST_OMC_DIR}/omshell_dioxus/web/index.html)
      omc_rust_omshell_qt_web_page()
      omc_rust_omnotebook_qt_web_page()
      omc_rust_omedit_qt_web_page()
    else()
      message(STATUS "OMShell web pages skipped: RUST_OMC_WASM_MODE is a Node host "
                     "(set web-release/web-debug to build them).")
    endif()
  endif()
endfunction()
