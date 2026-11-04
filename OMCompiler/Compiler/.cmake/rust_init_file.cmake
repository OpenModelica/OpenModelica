# libomc_init (SimulationRuntime/rust/openmodelica_init_file): reads
# <prefix>_init.bin for omc's readInitFile and for OMEdit. Built from the
# runtime workspace root like libomc_result.
# Defines the IMPORTED target omc::init and the rust_omc_init target.
include(${CMAKE_CURRENT_LIST_DIR}/rust_cargo.cmake)

function(omc_init_file_library)
  find_program(CARGO_EXECUTABLE cargo)
  if(NOT CARGO_EXECUTABLE)
    message(FATAL_ERROR
      "cargo was not found. OpenModelica reads <prefix>_init.bin through the Rust "
      "library libomc_init; install a stable Rust toolchain.")
  endif()
  set(_workspace ${CMAKE_CURRENT_SOURCE_DIR}/OMCompiler/SimulationRuntime/rust)
  set(_crate ${_workspace}/openmodelica_init_file)
  set(_target_dir ${CMAKE_CURRENT_BINARY_DIR}/rust-init-target)
  omc_rust_cargo_command(${_target_dir} omc_init)
  if(WIN32 OR RUST_OMC_TARGET MATCHES "windows")
    set(_lib ${_out}/omc_init.dll)
    if(MSVC OR RUST_OMC_TARGET MATCHES "msvc$")
      set(_implib ${_out}/omc_init.dll.lib)
    else()
      set(_implib ${_out}/libomc_init.dll.a)
    endif()
  elseif(APPLE OR RUST_OMC_TARGET MATCHES "apple-darwin$")
    set(_lib ${_out}/libomc_init.dylib)
  else()
    set(_lib ${_out}/libomc_init.so)
  endif()
  file(GLOB_RECURSE _rust_srcs CONFIGURE_DEPENDS
       ${_crate}/src/*.rs ${_crate}/Cargo.toml ${_crate}/include/omc_init_file.h)
  add_custom_command(
    OUTPUT ${_lib}
    WORKING_DIRECTORY ${_workspace}
    ${OMC_JOB_SERVER_AWARE}
    COMMAND ${_env} ${CARGO_EXECUTABLE} ${_cargo_cmd} --release --target-dir ${_target_dir} ${_target_flag} -p openmodelica_init_file
    DEPENDS ${_rust_srcs}
    COMMENT "Rust: building libomc_init"
    VERBATIM)
  add_custom_target(rust_omc_init ALL DEPENDS ${_lib})

  add_library(omc::init SHARED IMPORTED GLOBAL)
  set_target_properties(omc::init PROPERTIES
    IMPORTED_LOCATION ${_lib}
    IMPORTED_NO_SONAME TRUE
    INTERFACE_INCLUDE_DIRECTORIES ${_crate}/include)
  # Component omc: omcruntime links this PUBLIC. Called from the top-level CMakeLists.txt,
  # where the default component is the catch-all, so it has to be spelled out.
  if(_implib)
    set_target_properties(omc::init PROPERTIES IMPORTED_IMPLIB ${_implib})
    install(PROGRAMS ${_lib} DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT omc)
  else()
    install(PROGRAMS ${_lib} DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT omc)
  endif()
  add_dependencies(omc::init rust_omc_init)
  # Where the Windows install(RUNTIME_DEPENDENCIES) scans have to look for omc_init.dll.
  set(OMC_INIT_LIB_DIR ${_out} PARENT_SCOPE)
endfunction()
