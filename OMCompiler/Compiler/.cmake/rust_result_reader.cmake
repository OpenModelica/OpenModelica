# libomc_result (SimulationRuntime/rust/openmodelica_result_capi): the result
# readers of the GUI clients (OM_RUST_RESULT_READERS) and the result writers of
# the C simulation runtime (OM_RUST_RESULT_WRITERS). Built from the runtime
# workspace root like libSimulationRuntimeRust, so a stable cargo suffices.
# Defines the IMPORTED target omc::result and the rust_omc_result target.
function(omc_result_reader_library)
  find_program(CARGO_EXECUTABLE cargo)
  if(NOT CARGO_EXECUTABLE)
    message(FATAL_ERROR
      "OM_RUST_RESULT_READERS/OM_RUST_RESULT_WRITERS is ON but cargo was not found. Install a "
      "stable Rust toolchain, or configure with -DOM_RUST_RESULT_READERS=OFF "
      "-DOM_RUST_RESULT_WRITERS=OFF to use the C result readers and writers.")
  endif()
  set(_workspace ${CMAKE_CURRENT_SOURCE_DIR}/OMCompiler/SimulationRuntime/rust)
  set(_crate ${_workspace}/openmodelica_result_capi)
  set(_target_dir ${CMAKE_CURRENT_BINARY_DIR}/rust-result-target)
  # Cross-compiling (RUST_OMC_TARGET): the same drivers as
  # SimulationRuntime/rust/CMakeLists.txt uses for libSimulationRuntimeRust.
  set(_cargo_cmd build)
  set(_target_flag "")
  set(_out ${_target_dir}/release)
  if(RUST_OMC_TARGET)
    set(_target_flag --target ${RUST_OMC_TARGET})
    set(_out ${_target_dir}/${RUST_OMC_TARGET}/release)
    if(RUST_OMC_TARGET MATCHES "windows-msvc$")
      set(_cargo_cmd xwin build)
    elseif(RUST_OMC_TARGET MATCHES "apple-darwin$")
      set(_cargo_cmd zigbuild)
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
    JOB_SERVER_AWARE TRUE
    COMMAND ${CARGO_EXECUTABLE} ${_cargo_cmd} --release --target-dir ${_target_dir} ${_target_flag} -p openmodelica_result_capi
    DEPENDS ${_rust_srcs}
    COMMENT "Rust: building libomc_result (result-file readers for OMEdit/OMPlot)"
    VERBATIM)
  add_custom_target(rust_omc_result ALL DEPENDS ${_lib})

  add_library(omc::result SHARED IMPORTED GLOBAL)
  set_target_properties(omc::result PROPERTIES
    IMPORTED_LOCATION ${_lib}
    IMPORTED_NO_SONAME TRUE
    INTERFACE_INCLUDE_DIRECTORIES ${_crate}/include)
  if(_implib)
    set_target_properties(omc::result PROPERTIES IMPORTED_IMPLIB ${_implib})
    install(PROGRAMS ${_lib} DESTINATION ${CMAKE_INSTALL_BINDIR})
  else()
    install(PROGRAMS ${_lib} DESTINATION ${CMAKE_INSTALL_LIBDIR})
  endif()
  add_dependencies(omc::result rust_omc_result)
endfunction()
