# libomcruntime_rust (Compiler/runtime/rust): the parts of the C omc's compiler
# runtime written in Rust, linked statically into omcruntime and OMEdit. Built
# from its own cargo workspace root, so a stable cargo suffices.
# Defines the IMPORTED target omc::runtime_rust.
include(${CMAKE_CURRENT_LIST_DIR}/rust_cargo.cmake)
set(_omc_runtime_rust_dir ${CMAKE_CURRENT_LIST_DIR}/../runtime/rust)

function(omc_runtime_rust_library)
  find_program(CARGO_EXECUTABLE cargo REQUIRED)
  set(_crate ${_omc_runtime_rust_dir})
  set(_zip ${_crate}/../../OpenModelica.rs/openmodelica_zip)
  set(_target_dir ${CMAKE_CURRENT_BINARY_DIR}/rust-omcruntime-target)
  omc_rust_cargo_command(${_target_dir})
  if(MSVC OR RUST_OMC_TARGET MATCHES "msvc$")
    set(_lib ${_out}/omcruntime_rust.lib)
  else()
    set(_lib ${_out}/libomcruntime_rust.a)
  endif()
  file(GLOB_RECURSE _rust_srcs CONFIGURE_DEPENDS
       ${_crate}/src/*.rs ${_zip}/src/*.rs
       ${_crate}/../../OpenModelica.rs/openmodelica_wasi/src/*.rs)
  add_custom_command(
    OUTPUT ${_lib}
    WORKING_DIRECTORY ${_crate}
    ${OMC_JOB_SERVER_AWARE}
    COMMAND ${_env} ${CARGO_EXECUTABLE} ${_cargo_cmd} --release --locked --target-dir ${_target_dir} ${_target_flag}
    DEPENDS ${_rust_srcs} ${_crate}/Cargo.toml ${_crate}/Cargo.lock ${_zip}/Cargo.toml
    COMMENT "Rust: building libomcruntime_rust"
    VERBATIM)
  add_custom_target(rust_omcruntime DEPENDS ${_lib})

  add_library(omc::runtime_rust STATIC IMPORTED GLOBAL)
  set_target_properties(omc::runtime_rust PROPERTIES
    IMPORTED_LOCATION ${_lib}
    INTERFACE_INCLUDE_DIRECTORIES ${_crate}/include)
  add_dependencies(omc::runtime_rust rust_omcruntime)
  # What the Rust standard library needs (rustc --print native-static-libs).
  if(WIN32 OR RUST_OMC_TARGET MATCHES "windows")
    set_property(TARGET omc::runtime_rust PROPERTY INTERFACE_LINK_LIBRARIES ws2_32 userenv ntdll bcrypt advapi32)
  elseif(NOT APPLE AND NOT RUST_OMC_TARGET MATCHES "apple-darwin$")
    find_package(Threads REQUIRED)
    set_property(TARGET omc::runtime_rust PROPERTY INTERFACE_LINK_LIBRARIES Threads::Threads ${CMAKE_DL_LIBS} m)
  endif()
endfunction()
