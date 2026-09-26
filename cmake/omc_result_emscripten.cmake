# libomc_result for the Qt-for-WebAssembly GUI clients: defines the IMPORTED
# static library omc::result. Needs OM_ROOT and omc_job_server.cmake.
#
# Asyncify aborts on the wasm exception handling rustc emits for this target by
# default and ships inside the precompiled std, so std is rebuilt here with
# emscripten's JS exceptions (nightly + rust-src).
set(RESULT_WORKSPACE ${OM_ROOT}/OMCompiler/SimulationRuntime/rust)
set(RESULT_CRATE ${RESULT_WORKSPACE}/openmodelica_result_capi)
set(RESULT_TARGET_DIR ${CMAKE_BINARY_DIR}/omc-result-emscripten)
set(RESULT_LIB ${RESULT_TARGET_DIR}/wasm32-unknown-emscripten/release/libomc_result.a)
find_program(CARGO_EXECUTABLE cargo)
if(NOT CARGO_EXECUTABLE)
  message(FATAL_ERROR "cargo was not found; the web GUI clients read result files through "
                      "libomc_result. Install a nightly Rust toolchain with the rust-src "
                      "component and `rustup target add wasm32-unknown-emscripten`.")
endif()
# Every crate cargo compiles for this library; one left out is one cmake will not
# rebuild for, and the stale archive looks fine from the outside.
set(RESULT_CRATES
    ${RESULT_CRATE}
    ${RESULT_WORKSPACE}/openmodelica_result_files
    ${RESULT_WORKSPACE}/openmodelica_result_diff
    ${RESULT_WORKSPACE}/openmodelica_mat_reader
    ${RESULT_WORKSPACE}/openmodelica_arrow_writer
    ${RESULT_WORKSPACE}/openmodelica_mat_writer
    ${RESULT_WORKSPACE}/openmodelica_plt_writer
    ${OM_ROOT}/OMCompiler/Compiler/OpenModelica.rs/openmodelica_wasi)
set(RESULT_GLOBS ${RESULT_CRATE}/include/omc_result.h)
foreach(crate ${RESULT_CRATES})
  list(APPEND RESULT_GLOBS ${crate}/src/*.rs ${crate}/Cargo.toml)
endforeach()
file(GLOB_RECURSE RESULT_SOURCES CONFIGURE_DEPENDS ${RESULT_GLOBS})
add_custom_command(
  OUTPUT ${RESULT_LIB}
  WORKING_DIRECTORY ${RESULT_WORKSPACE}
  ${OMC_JOB_SERVER_AWARE}
  COMMAND ${CMAKE_COMMAND} -E env RUSTFLAGS=-Zemscripten-wasm-eh=no
          ${CARGO_EXECUTABLE} rustc -Zbuild-std=std,panic_abort
          --release --target wasm32-unknown-emscripten
          --target-dir ${RESULT_TARGET_DIR} -p openmodelica_result_capi
          --crate-type staticlib
  DEPENDS ${RESULT_SOURCES}
  COMMENT "Rust: building libomc_result (wasm32-unknown-emscripten)"
  VERBATIM)
add_custom_target(rust_omc_result DEPENDS ${RESULT_LIB})
add_library(omc::result STATIC IMPORTED GLOBAL)
set_target_properties(omc::result PROPERTIES
  IMPORTED_LOCATION ${RESULT_LIB}
  INTERFACE_INCLUDE_DIRECTORIES ${RESULT_CRATE}/include)
add_dependencies(omc::result rust_omc_result)
