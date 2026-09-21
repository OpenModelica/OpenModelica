# The host SUNDIALS and Ipopt archives the Rust crates link, collected into fixed
# directories and published as global properties: the cargo environment cannot
# carry a generator expression, and both libSimulationRuntimeRust and (when omc
# is the Rust port) libOpenModelicaCompiler need the same hand-off.
#
# Included from OMCompiler/CMakeLists.txt after 3rdParty and before Compiler, so
# that `--simCodeTarget=C+Rust` gets CVODE/IDA and `method="optimization"` in a
# build of the bootstrapped C omc as well.

# The archives are the C runtime's own (3rdParty), not a second build: they are
# already position-independent (`libSimulationRuntimeC.so` links them), and
# reusing them leaves the two copies identical should both end up in one process.
# IDA's default linear solver is KLU, so SuiteSparse comes too.
if(TARGET sundials_cvode_static)
  set(RUST_SUNDIALS_NATIVE_DIR ${CMAKE_BINARY_DIR}/rust-sundials-native
      CACHE PATH "Directory the host SUNDIALS archives are collected into.")
  set(_native_sundials_libs
    sundials_kinsol_static
    sundials_cvode_static sundials_idas_static sundials_sunlinsolklu_static
    sundials_sunlinsoldense_static sundials_sunmatrixsparse_static
    sundials_sunmatrixdense_static sundials_nvecserial_static
    sundials_core_static
    KLU_static AMD_static COLAMD_static BTF_static SuiteSparseConfig_static)
  set(_native_sundials_files "")
  foreach(_lib IN LISTS _native_sundials_libs)
    list(APPEND _native_sundials_files $<TARGET_FILE:${_lib}>)
  endforeach()
  add_custom_target(rust_sundials_native_collect
    COMMAND ${CMAKE_COMMAND} -E make_directory ${RUST_SUNDIALS_NATIVE_DIR}/lib
    COMMAND ${CMAKE_COMMAND} -E copy
      ${_native_sundials_files} ${RUST_SUNDIALS_NATIVE_DIR}/lib/
    DEPENDS ${_native_sundials_libs}
    COMMENT "Rust: collecting host SUNDIALS archives -> ${RUST_SUNDIALS_NATIVE_DIR}/lib/"
    VERBATIM)
  # The wasm archives are 32-bit-index builds and this one is whatever the C
  # runtime uses, so the bindings' `sunindextype` follows the archive.
  set_property(GLOBAL PROPERTY OMC_RUST_SUNDIALS_NATIVE_DIR ${RUST_SUNDIALS_NATIVE_DIR})
  set_property(GLOBAL PROPERTY OMC_RUST_SUNDIALS_INDEX_SIZE ${SUNDIALS_INDEX_SIZE})
endif()

# Ipopt for `method="optimization"` (the classic dynamic-optimization runtime).
# Host-only: MUMPS is Fortran 90, so there is no wasm build and an in-wasm runtime
# reports the same "Ipopt is needed but not available" a C runtime without
# OMC_HAVE_IPOPT does.
if(OM_OMC_ENABLE_OPTIMIZATION AND TARGET ipopt)
  set(RUST_IPOPT_NATIVE_DIR ${CMAKE_BINARY_DIR}/rust-ipopt-native
      CACHE PATH "Directory the host Ipopt archives are collected into.")
  set(_native_ipopt_libs ipopt dmumps mumps_common seq metis)
  set(_native_ipopt_files "")
  foreach(_lib IN LISTS _native_ipopt_libs)
    list(APPEND _native_ipopt_files $<TARGET_FILE:${_lib}>)
  endforeach()
  add_custom_target(rust_ipopt_native_collect
    COMMAND ${CMAKE_COMMAND} -E make_directory ${RUST_IPOPT_NATIVE_DIR}/lib
    COMMAND ${CMAKE_COMMAND} -E copy
      ${_native_ipopt_files} ${RUST_IPOPT_NATIVE_DIR}/lib/
    DEPENDS ${_native_ipopt_libs}
    COMMENT "Rust: collecting host Ipopt archives -> ${RUST_IPOPT_NATIVE_DIR}/lib/"
    VERBATIM)
  set_property(GLOBAL PROPERTY OMC_RUST_IPOPT_NATIVE_DIR ${RUST_IPOPT_NATIVE_DIR})
endif()
