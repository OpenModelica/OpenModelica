# libSimulationRuntimeRust: the simulation runtime `--simCodeTarget=C` links
# generated C against.
#
# The crate is a member of the compiler workspace, so an omc build compiles it
# and its dependencies exactly once. When omc is the Rust port
# (OM_OMC_ENABLE_RUST), build from the same per-build working copy
# rust_omc.cmake mirrors into, sharing its cargo target dir. Otherwise there is
# no compiler workspace to load -- a clean checkout has no generated lib.rs --
# so build through the workspace rooted in this directory, which reaches the same
# crates as plain path dependencies (see Cargo.toml).

find_program(CARGO_EXECUTABLE cargo)
if(NOT CARGO_EXECUTABLE)
  message(FATAL_ERROR "cargo was not found; libSimulationRuntimeRust needs a stable Rust toolchain.")
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
  elseif(RUST_OMC_TARGET MATCHES "linux-gnu$")
    # Another Linux architecture needs no cargo driver, just the cross linker --
    # the same one the C half of this build uses.
    string(TOUPPER ${RUST_OMC_TARGET} _simrt_target_env)
    string(REPLACE "-" "_" _simrt_target_env ${_simrt_target_env})
    set(_simrt_linker_env
        "CARGO_TARGET_${_simrt_target_env}_LINKER=${CMAKE_C_COMPILER}"
        "PKG_CONFIG_ALLOW_CROSS=1"
        "PKG_CONFIG_LIBDIR=/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/pkgconfig:/usr/share/pkgconfig")
  else()
    message(WARNING
      "RUST_OMC_TARGET=${RUST_OMC_TARGET}: libSimulationRuntimeRust will be built "
      "with a plain `cargo build --target`, which needs a linker for that target "
      "on PATH. Only *-windows-msvc (cargo-xwin), *-apple-darwin "
      "(cargo-zigbuild) and *-linux-gnu are wired.")
  endif()
endif()

set(_simrt_so ${_simrt_target_dir}/${_simrt_artifact_subdir}/${CMAKE_SHARED_LIBRARY_PREFIX}SimulationRuntimeRust${CMAKE_SHARED_LIBRARY_SUFFIX})
# The same runtime as an archive, which a source-code FMU links. Its own cargo
# invocation and target directory, because two things must differ:
#
#  * no libOpenModelicaRuntimeC -- the FMU compiles that half from its own sources,
#    so the archive must leave those symbols undefined.
#  * no Ipopt and no PRIMME. `rustc` bundles a native static library into a
#    `staticlib`, so `-moo` would put Ipopt and MUMPS into every FMU (and with them
#    libgfortran), and PRIMME would make every FMU need a system LAPACK.
set(_simrt_fmu_target_dir ${_simrt_target_dir}-fmu)
set(_simrt_a ${_simrt_fmu_target_dir}/${_simrt_artifact_subdir}/${CMAKE_STATIC_LIBRARY_PREFIX}SimulationRuntimeRust${CMAKE_STATIC_LIBRARY_SUFFIX})

# The headers tests/abi_layout.rs compiles to check the ABI mirror against the
# real `simulation_data.h`; the test cannot find them from a mirrored working
# copy. `|`-separated: a `;` would make CMake split the env assignment into
# arguments, and a `:` is a Windows drive letter.
set(_simrt_headers "${CMAKE_CURRENT_SOURCE_DIR}/../c|${CMAKE_CURRENT_SOURCE_DIR}/../../3rdParty/gc/include")

set(_simrt_env ${CMAKE_COMMAND} -E env "OMC_SIMRT_INCLUDE_DIRS=${_simrt_headers}")
if(_simrt_sdkroot)
  list(APPEND _simrt_env "SDKROOT=${_simrt_sdkroot}")
endif()
if(_simrt_linker_env)
  list(APPEND _simrt_env "${_simrt_linker_env}")
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
# MSVC has no lapack.lib/blas.lib for openmodelica_nls to name.
if(MSVC)
  set(_simrt_lapack "")
  foreach(_l IN LISTS LAPACK_LIBRARIES BLAS_LIBRARIES)
    if(IS_ABSOLUTE "${_l}" AND NOT _l IN_LIST _simrt_lapack)
      list(APPEND _simrt_lapack "${_l}")
    endif()
  endforeach()
  if(_simrt_lapack)
    list(JOIN _simrt_lapack "|" _simrt_lapack)
    list(APPEND _simrt_env "OMC_LAPACK_LINK=${_simrt_lapack}")
  endif()
endif()

# libOpenModelicaRuntimeC, which owns the state both runtimes share with the
# generated code (see build.rs). libSimulationRuntimeC links it too.
if(TARGET OpenModelicaRuntimeC)
  list(APPEND _simrt_env "OMC_RUNTIME_C_DIR=$<TARGET_FILE_DIR:OpenModelicaRuntimeC>")
  # A static archive (MSVC) carries none of its own dependencies, so name them
  # too. `|`-separated: a `;` would split the env assignment into arguments.
  get_target_property(_simrt_rtc_type OpenModelicaRuntimeC TYPE)
  if(_simrt_rtc_type STREQUAL "STATIC_LIBRARY")
    set(_simrt_rtc_link "$<TARGET_LINKER_FILE:OpenModelicaRuntimeC>")
    if(TARGET PThreads4W::PThreads4W)
      string(APPEND _simrt_rtc_link "|$<TARGET_LINKER_FILE:PThreads4W::PThreads4W>")
    endif()
    # Re-exporting the archive below pulls in members nothing referenced before,
    # and with them utility.c's regex, realString.c's ryu and the registry calls.
    foreach(_simrt_rtc_dep omcregex ryu)
      if(TARGET ${_simrt_rtc_dep})
        string(APPEND _simrt_rtc_link "|$<TARGET_LINKER_FILE:${_simrt_rtc_dep}>")
      endif()
    endforeach()
    if(WIN32)
      # Lower case: Windows does not care, and the xwin SDK ships it under this
      # spelling on a case-sensitive filesystem.
      string(APPEND _simrt_rtc_link "|advapi32.lib")
    endif()
    list(APPEND _simrt_env "OMC_RUNTIME_C_LINK=${_simrt_rtc_link}")
    if(WIN32)
      # Absorbing the archive is not enough on Windows: a cdylib exports only
      # what Rust marks dllexport, so --simCodeTarget=C found none of the C
      # runtime. An ELF .so exports it anyway.
      find_program(OMC_NM_EXECUTABLE NAMES llvm-nm nm)
      if(OMC_NM_EXECUTABLE)
        set(_simrt_def "${CMAKE_CURRENT_BINARY_DIR}/OpenModelicaRuntimeC-reexport.rsp")
        set(_simrt_def_command COMMAND ${CMAKE_COMMAND}
            "-DLIB=$<TARGET_LINKER_FILE:OpenModelicaRuntimeC>" "-DOUT=${_simrt_def}"
            "-DNM=${OMC_NM_EXECUTABLE}"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/reexport_def.cmake")
        list(APPEND _simrt_env "OMC_RUNTIME_C_DEF=${_simrt_def}")
      else()
        message(WARNING "No llvm-nm/nm found: libSimulationRuntimeRust will not "
                        "re-export the C runtime, so --simCodeTarget=C cannot link.")
      endif()
    endif()
  endif()
endif()

add_custom_target(SimulationRuntimeRust ALL
  WORKING_DIRECTORY ${_simrt_workspace}
  ${OMC_JOB_SERVER_AWARE}
  ${_simrt_def_command}
  COMMAND ${_simrt_env} ${CARGO_EXECUTABLE} ${_simrt_cargo_cmd} --target-dir ${_simrt_target_dir}
          ${_simrt_target_flag} ${_simrt_profile_flag} -p openmodelica_simulation_runtime
  BYPRODUCTS ${_simrt_so}
  COMMENT "Rust: building libSimulationRuntimeRust (${OM_RUST_SIM_RUNTIME_PROFILE})"
  VERBATIM)
if(TARGET rust_src_sync)
  add_dependencies(SimulationRuntimeRust rust_src_sync)
endif()

# The archive a source-code FMU links. `_simrt_env` minus the two entries above;
# everything else (SUNDIALS, PRIMME, the cross-compilation driver) is the same.
set(_simrt_fmu_env "")
foreach(_e IN LISTS _simrt_env)
  if(NOT _e MATCHES "^OMC_RUNTIME_C_(DIR|LINK|DEF)=" AND NOT _e MATCHES "^OMC_IPOPT_NATIVE_DIR="
     AND NOT _e MATCHES "^OMC_PRIMME_(NATIVE_DIR|INCLUDE_DIR)=")
    list(APPEND _simrt_fmu_env "${_e}")
  endif()
endforeach()
list(APPEND _simrt_fmu_env "OMC_SIMRT_FMI=1")
# Only the archive: cargo also links a dependency's cdylib, which cannot link on
# Windows without the C half. cargo-zigbuild has no `rustc`.
if(_simrt_cargo_cmd STREQUAL "zigbuild")
  set(_simrt_fmu_cargo_cmd zigbuild)
else()
  string(REPLACE "build" "rustc" _simrt_fmu_cargo_cmd "${_simrt_cargo_cmd}")
  list(APPEND _simrt_fmu_cargo_cmd -p openmodelica_simulation_runtime --lib --crate-type staticlib)
endif()
add_custom_target(SimulationRuntimeRustFmu ALL
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/openmodelica_simulation_runtime_fmu
  ${OMC_JOB_SERVER_AWARE}
  COMMAND ${_simrt_fmu_env} ${CARGO_EXECUTABLE} ${_simrt_fmu_cargo_cmd} --target-dir ${_simrt_fmu_target_dir}
          ${_simrt_target_flag} ${_simrt_profile_flag}
  BYPRODUCTS ${_simrt_a}
  COMMENT "Rust: building libSimulationRuntimeRust.a for source-code FMUs"
  VERBATIM)
add_dependencies(SimulationRuntimeRustFmu SimulationRuntimeRust)
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

if(WIN32)
  # The DLL belongs next to the executables that load it, and cargo names the
  # import library <dll>.lib, not <name>.lib.
  install(PROGRAMS ${_simrt_so} DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT omc)
  install(FILES ${_simrt_so}.lib DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT omc
          RENAME SimulationRuntimeRust.lib)
else()
  install(PROGRAMS ${_simrt_so} DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT omc)
endif()
# Component fmu: it travels with the rest of what a source-code FMU is built from.
# MSVC names it SimulationRuntimeRust.lib, which is the import library above.
install(FILES ${_simrt_a} DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT fmu
        RENAME libSimulationRuntimeRust.a)

# The crates themselves, for `--fmiSources=slim` / `=full` to put in the FMU.
# The layout is the checkout's, because the manifests reach openmodelica_lapack by
# a relative path: <root>/SimulationRuntime/rust beside <root>/Compiler/OpenModelica.rs.
set(_simrt_fmu_sources ${CMAKE_INSTALL_DATAROOTDIR}/omc/sources/rust)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/
        DESTINATION ${_simrt_fmu_sources}/SimulationRuntime/rust
        COMPONENT fmu
        PATTERN "target" EXCLUDE
        PATTERN "CMakeLists.txt" EXCLUDE
        PATTERN "*.cmake" EXCLUDE)
foreach(_simrt_fmu_crate openmodelica_lapack openmodelica_fmi3_wasm)
  install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../../Compiler/OpenModelica.rs/${_simrt_fmu_crate}/
          DESTINATION ${_simrt_fmu_sources}/Compiler/OpenModelica.rs/${_simrt_fmu_crate}
          COMPONENT fmu
          PATTERN "target" EXCLUDE)
endforeach()
