# libSimulationRuntimeRust: the simulation runtime `--simCodeTarget=C+Rust` links
# generated C against, instead of libSimulationRuntimeC.
#
# The crate is a member of the compiler workspace, so an omc build compiles it
# and its dependencies exactly once. When omc is the Rust port
# (OM_OMC_ENABLE_RUST), build from the same per-build working copy
# rust_omc.cmake mirrors into, sharing its cargo target dir. Otherwise there is
# no compiler workspace to load -- a clean checkout has no generated lib.rs --
# so build through the workspace rooted in this directory, which reaches the same
# crates as plain path dependencies (see Cargo.toml).

# Opt-in: building it needs a Rust toolchain a C-only build does not require.
option(OM_ENABLE_RUST_SIM_RUNTIME
       "Build libSimulationRuntimeRust, the runtime --simCodeTarget=C+Rust links." OFF)
if(NOT OM_ENABLE_RUST_SIM_RUNTIME)
  return()
endif()

find_program(CARGO_EXECUTABLE cargo)
if(NOT CARGO_EXECUTABLE)
  message(STATUS "cargo not found: skipping libSimulationRuntimeRust (--simCodeTarget=C+Rust will not link).")
  return()
endif()

# rust_omc.cmake publishes its per-build working copy and cargo target directory
# when omc itself is the Rust port; without it, build from the canonical tree.
get_property(_simrt_workspace GLOBAL PROPERTY OMC_RUST_WORKSPACE_DIR)
if(NOT _simrt_workspace OR NOT EXISTS ${_simrt_workspace}/Cargo.toml)
  set(_simrt_workspace ${CMAKE_CURRENT_SOURCE_DIR})
endif()
get_property(_simrt_target_dir GLOBAL PROPERTY OMC_RUST_TARGET_DIR)
if(NOT _simrt_target_dir)
  set(_simrt_target_dir ${CMAKE_CURRENT_BINARY_DIR}/rust-target)
endif()

# A simulation runtime compiled without optimization is not worth having, so this
# does not follow CMAKE_BUILD_TYPE the way the C runtime does.
set(OM_RUST_SIM_RUNTIME_PROFILE "release" CACHE STRING
    "Cargo profile for libSimulationRuntimeRust: release or debug.")
if(OM_RUST_SIM_RUNTIME_PROFILE STREQUAL "release")
  set(_simrt_profile_flag --release)
  set(_simrt_profile_dir release)
else()
  set(_simrt_profile_flag "")
  set(_simrt_profile_dir debug)
endif()

# Cross-compiling (RUST_OMC_TARGET, as the omc's own cross build uses): cargo
# needs a driver that knows the target's toolchain, and the same MSVC/macOS SDK
# the C libraries here were built against.
set(_simrt_cargo_cmd build)
set(_simrt_target_flag "")
set(_simrt_artifact_subdir ${_simrt_profile_dir})
if(RUST_OMC_TARGET)
  set(_simrt_target_flag --target ${RUST_OMC_TARGET})
  set(_simrt_artifact_subdir ${RUST_OMC_TARGET}/${_simrt_profile_dir})
  if(RUST_OMC_TARGET MATCHES "windows-msvc$")
    set(_simrt_cargo_cmd xwin build)
  elseif(RUST_OMC_TARGET MATCHES "apple-darwin$")
    set(_simrt_cargo_cmd zigbuild)
    # Both cargo-zigbuild and build.rs read the SDK from SDKROOT; handed over
    # below, where _simrt_env exists.
    set(_simrt_sdkroot ${CMAKE_OSX_SYSROOT})
  else()
    message(WARNING
      "RUST_OMC_TARGET=${RUST_OMC_TARGET}: libSimulationRuntimeRust will be built "
      "with a plain `cargo build --target`, which needs a linker for that target "
      "on PATH. Only *-windows-msvc (cargo-xwin) and *-apple-darwin "
      "(cargo-zigbuild) are wired.")
  endif()
endif()

set(_simrt_so ${_simrt_target_dir}/${_simrt_artifact_subdir}/${CMAKE_SHARED_LIBRARY_PREFIX}SimulationRuntimeRust${CMAKE_SHARED_LIBRARY_SUFFIX})

# The headers tests/abi_layout.rs compiles to check the ABI mirror against the
# real `simulation_data.h`; the test cannot find them from a mirrored working
# copy. `|`-separated: a `;` would make CMake split the env assignment into
# arguments, and a `:` is a Windows drive letter.
set(_simrt_headers "${CMAKE_CURRENT_SOURCE_DIR}/../c|${CMAKE_CURRENT_SOURCE_DIR}/../../3rdParty/gc/include")

set(_simrt_env ${CMAKE_COMMAND} -E env "OMC_SIMRT_INCLUDE_DIRS=${_simrt_headers}")
if(_simrt_sdkroot)
  list(APPEND _simrt_env "SDKROOT=${_simrt_sdkroot}")
endif()
# The archives native_solver_archives.cmake collected, so the driver gets
# CVODE/IDA. Both or neither: openmodelica_solvers' build script needs the index
# size whenever the archive directory is given.
get_property(_simrt_sundials GLOBAL PROPERTY OMC_RUST_SUNDIALS_NATIVE_DIR)
get_property(_simrt_sundials_ix GLOBAL PROPERTY OMC_RUST_SUNDIALS_INDEX_SIZE)
if(_simrt_sundials AND _simrt_sundials_ix)
  list(APPEND _simrt_env
       "OMC_SUNDIALS_NATIVE_DIR=${_simrt_sundials}"
       "OMC_SUNDIALS_NATIVE_INDEX_SIZE=${_simrt_sundials_ix}")
endif()
# The same hand-off for Ipopt, which `method="optimization"` needs; without it
# `openmodelica_sim_meta` builds without `cfg(ipopt)` and the driver reports the
# solver as unavailable, exactly as a C runtime without OMC_HAVE_IPOPT does.
get_property(_simrt_ipopt GLOBAL PROPERTY OMC_RUST_IPOPT_NATIVE_DIR)
if(_simrt_ipopt)
  list(APPEND _simrt_env "OMC_IPOPT_NATIVE_DIR=${_simrt_ipopt}")
endif()
# PRIMME, the sparse SVD behind `-lv=LOG_NLS_SVD`: the archive 3rdParty already
# builds for libSimulationRuntimeC. Selected by the environment, not a cargo
# feature: cargo refuses --features for a package outside the workspace, which
# openmodelica_simulation_runtime is to the workspace rooted here.
if(TARGET primme)
  list(APPEND _simrt_env
       "OMC_PRIMME_NATIVE_DIR=$<TARGET_FILE_DIR:primme>"
       "OMC_PRIMME_INCLUDE_DIR=${CMAKE_CURRENT_SOURCE_DIR}/../../3rdParty/primme-3.2.3/include")
endif()

# libOpenModelicaRuntimeC, which owns the state both runtimes share with the
# generated code (see build.rs). libSimulationRuntimeC links it too.
if(TARGET OpenModelicaRuntimeC)
  list(APPEND _simrt_env "OMC_RUNTIME_C_DIR=$<TARGET_FILE_DIR:OpenModelicaRuntimeC>")
  # A static archive (MSVC) carries none of its own dependencies, so name them
  # too. `|`-separated: a `;` would split the env assignment into arguments.
  get_target_property(_simrt_rtc_type OpenModelicaRuntimeC TYPE)
  if(_simrt_rtc_type STREQUAL "STATIC_LIBRARY")
    set(_simrt_rtc_link "$<TARGET_LINKER_FILE:OpenModelicaRuntimeC>|$<TARGET_LINKER_FILE:omcgc>")
    if(TARGET PThreads4W::PThreads4W)
      string(APPEND _simrt_rtc_link "|$<TARGET_LINKER_FILE:PThreads4W::PThreads4W>")
    endif()
    list(APPEND _simrt_env "OMC_RUNTIME_C_LINK=${_simrt_rtc_link}")
  endif()
endif()

add_custom_target(SimulationRuntimeRust ALL
  WORKING_DIRECTORY ${_simrt_workspace}
  JOB_SERVER_AWARE TRUE
  COMMAND ${_simrt_env} ${CARGO_EXECUTABLE} ${_simrt_cargo_cmd} --target-dir ${_simrt_target_dir}
          ${_simrt_target_flag} ${_simrt_profile_flag} -p openmodelica_simulation_runtime
  BYPRODUCTS ${_simrt_so}
  COMMENT "Rust: building libSimulationRuntimeRust (${OM_RUST_SIM_RUNTIME_PROFILE})"
  VERBATIM)
if(TARGET rust_src_sync)
  add_dependencies(SimulationRuntimeRust rust_src_sync)
endif()
if(TARGET rust_sundials_native_collect)
  add_dependencies(SimulationRuntimeRust rust_sundials_native_collect)
endif()
if(TARGET rust_ipopt_native_collect)
  add_dependencies(SimulationRuntimeRust rust_ipopt_native_collect)
endif()
if(TARGET primme)
  add_dependencies(SimulationRuntimeRust primme)
endif()
if(TARGET OpenModelicaRuntimeC)
  add_dependencies(SimulationRuntimeRust OpenModelicaRuntimeC)
endif()

install(PROGRAMS ${_simrt_so} DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT omc)
