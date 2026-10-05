# libomc_result (SimulationRuntime/rust/openmodelica_result_capi): the result
# readers of omc and the GUI clients and the result writers of the C simulation
# runtime. Built from the runtime workspace root like libSimulationRuntimeRust,
# so a stable cargo suffices.
# Defines the IMPORTED target omc::result and the rust_omc_result target.
function(omc_result_reader_library)
  find_program(CARGO_EXECUTABLE cargo)
  if(NOT CARGO_EXECUTABLE)
    message(FATAL_ERROR
      "cargo was not found. OpenModelica reads and writes result files through the Rust "
      "library libomc_result; install a stable Rust toolchain.")
  endif()
  set(_workspace ${CMAKE_CURRENT_SOURCE_DIR}/OMCompiler/SimulationRuntime/rust)
  set(_crate ${_workspace}/openmodelica_result_capi)
  set(_target_dir ${CMAKE_CURRENT_BINARY_DIR}/rust-result-target)
  # Cross-compiling (RUST_OMC_TARGET): the same drivers as
  # SimulationRuntime/rust/CMakeLists.txt uses for libSimulationRuntimeRust.
  set(_cargo_cmd build)
  set(_target_flag "")
  set(_out ${_target_dir}/release)
  set(_env ${CMAKE_COMMAND} -E env)
  if(RUST_OMC_TARGET)
    set(_target_flag --target ${RUST_OMC_TARGET})
    set(_out ${_target_dir}/${RUST_OMC_TARGET}/release)
    if(RUST_OMC_TARGET MATCHES "windows-msvc$")
      set(_cargo_cmd xwin build)
    elseif(RUST_OMC_TARGET MATCHES "apple-darwin$")
      set(_cargo_cmd zigbuild)
      # zig ships no Apple frameworks, so the link needs the SDK (CoreFoundation,
      # via chrono's iana-time-zone). ld64 would otherwise name the dylib by its
      # path in this build tree; @rpath defers that to whoever loads it.
      list(APPEND _env "SDKROOT=${CMAKE_OSX_SYSROOT}"
           "RUSTFLAGS=-Clink-arg=-Wl,-install_name,@rpath/libomc_result.dylib")
    elseif(RUST_OMC_TARGET MATCHES "linux-gnu$")
      # Plain `cargo build` is right for another Linux architecture, but the
      # linker has to be named or rustc calls the host `cc` -- which rejects the
      # AArch64-only --fix-cortex-a53-843419 that rustc passes for the target.
      string(TOUPPER ${RUST_OMC_TARGET} _res_target_env)
      string(REPLACE "-" "_" _res_target_env ${_res_target_env})
      list(APPEND _env "CARGO_TARGET_${_res_target_env}_LINKER=${CMAKE_C_COMPILER}"
           "PKG_CONFIG_ALLOW_CROSS=1"
           "PKG_CONFIG_LIBDIR=/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/pkgconfig:/usr/share/pkgconfig")
    endif()
  endif()
  if(WIN32 OR RUST_OMC_TARGET MATCHES "windows")
    set(_lib ${_out}/omc_result.dll)
    if(MSVC OR RUST_OMC_TARGET MATCHES "msvc$")
      set(_implib ${_out}/omc_result.dll.lib)
    else()
      set(_implib ${_out}/libomc_result.dll.a)
    endif()
  elseif(APPLE OR RUST_OMC_TARGET MATCHES "apple-darwin$")
    set(_lib ${_out}/libomc_result.dylib)
  else()
    set(_lib ${_out}/libomc_result.so)
  endif()
  file(GLOB_RECURSE _rust_srcs CONFIGURE_DEPENDS
       ${_crate}/src/*.rs ${_crate}/Cargo.toml ${_crate}/include/omc_result.h
       ${_workspace}/openmodelica_result_files/src/*.rs
       ${_workspace}/openmodelica_mat_reader/src/*.rs
       ${_workspace}/openmodelica_arrow_writer/src/*.rs
       ${_workspace}/openmodelica_mat_writer/src/*.rs
       ${CMAKE_CURRENT_SOURCE_DIR}/OMCompiler/Compiler/OpenModelica.rs/openmodelica_wasi/src/*.rs)
  add_custom_command(
    OUTPUT ${_lib}
    WORKING_DIRECTORY ${_workspace}
    ${OMC_JOB_SERVER_AWARE}
    COMMAND ${_env} ${CARGO_EXECUTABLE} ${_cargo_cmd} --release --target-dir ${_target_dir} ${_target_flag} -p openmodelica_result_capi
    DEPENDS ${_rust_srcs}
    COMMENT "Rust: building libomc_result"
    VERBATIM)
  add_custom_target(rust_omc_result ALL DEPENDS ${_lib})

  add_library(omc::result SHARED IMPORTED GLOBAL)
  set_target_properties(omc::result PROPERTIES
    IMPORTED_LOCATION ${_lib}
    IMPORTED_NO_SONAME TRUE
    INTERFACE_INCLUDE_DIRECTORIES ${_crate}/include)
  # Component omc: omcruntime links this PUBLIC, so omc itself does not run without it. That
  # also puts it below OMPlot, OMEdit and the simulation runtime, which link it too -- they all
  # depend on the omc component already. This function is called from the top-level
  # CMakeLists.txt, where the default component is the catch-all, so it has to be spelled out.
  if(_implib)
    set_target_properties(omc::result PROPERTIES IMPORTED_IMPLIB ${_implib})
    install(PROGRAMS ${_lib} DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT omc)
  else()
    install(PROGRAMS ${_lib} DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT omc)
  endif()
  add_dependencies(omc::result rust_omc_result)
  # Where the Windows install(RUNTIME_DEPENDENCIES) scans have to look for omc_result.dll.
  set(OMC_RESULT_LIB_DIR ${_out} PARENT_SCOPE)
endfunction()
