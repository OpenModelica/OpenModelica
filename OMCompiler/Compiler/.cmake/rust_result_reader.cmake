# libomc_result (SimulationRuntime/rust/openmodelica_result_capi): the result
# readers of omc and the GUI clients and the result writers of the C simulation
# runtime. Built from the runtime workspace root like libSimulationRuntimeRust,
# so a stable cargo suffices.
# Defines the IMPORTED target omc::result and the rust_omc_result target.
include(${CMAKE_CURRENT_LIST_DIR}/rust_cargo.cmake)

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
  omc_rust_cargo_command(${_target_dir} omc_result)
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
