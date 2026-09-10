# omcCAPI — libOMCDLL
#
# A thin C-API wrapper around libOpenModelicaCompiler that lets external programs
# drive omc in-process (InitOMC / SendCommand / GetOMCVersion / FreeOMC / ...)
# instead of talking to a separate omc executable.

add_library(OMCDLL SHARED src/OMC.cpp)

# Force the "lib" prefix so the artifact is libOMCDLL.{dll,so,dylib} on every
# toolchain (previous releases shipped bin/libOMCDLL.dll).
set_target_properties(OMCDLL PROPERTIES PREFIX "lib" OUTPUT_NAME "OMCDLL")
target_compile_features(OMCDLL PRIVATE cxx_std_11)

target_include_directories(OMCDLL PRIVATE include)

# IMPORT_INTO      -> runtime / scripting-API symbols come in as dllimport
# BUILDING_OMC_DLL -> export this wrapper's own OMC_DLL functions
target_compile_definitions(OMCDLL PRIVATE IMPORT_INTO=1 BUILDING_OMC_DLL)

# Linking OpenModelicaCompiler pulls in, with the right INTERFACE include dirs,
# everything OMC.cpp needs: the generated OpenModelicaScriptingAPI.h
# (<build>/.../c_files), meta/meta_modelica.h and the MetaModelica runtime.
# omcgc is a separate shared library -> link it for GC_malloc_uncollectable /
# GC_free.
target_link_libraries(OMCDLL PRIVATE
  OpenModelicaCompiler
  omc::simrt::runtime
  omc::3rd::omcgc)

# Put libOMCDLL next to libOpenModelicaCompiler in the build tree so it can be
# used straight from there (dll -> .../bin on Windows, .so -> .../lib on ELF).
get_target_property(_omcdll_rt_dir  OpenModelicaCompiler RUNTIME_OUTPUT_DIRECTORY)
get_target_property(_omcdll_lib_dir OpenModelicaCompiler LIBRARY_OUTPUT_DIRECTORY)
if(_omcdll_rt_dir)
  set_target_properties(OMCDLL PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${_omcdll_rt_dir})
endif()
if(_omcdll_lib_dir)
  set_target_properties(OMCDLL PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${_omcdll_lib_dir})
endif()

if(APPLE)
  set_target_properties(OMCDLL PROPERTIES INSTALL_RPATH "@loader_path")
elseif(UNIX)
  set_target_properties(OMCDLL PROPERTIES INSTALL_RPATH "$ORIGIN")
endif()

install(TARGETS OMCDLL
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT omc
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT omc
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT omc)

install(FILES include/OMC.h include/OMCAPI.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        COMPONENT omc)


# ── Smoke test ───────────────────────────────────────────────────────────────
# test/verify_libOMCDLL.c dlopen()s the freshly built libOMCDLL and drives omc
# through the whole public API (the replacement for the old OMCTest.cpp).
# Registered as the CTest `omcCAPI-libOMCDLL-usable`. Needs CMake >= 3.22 for
# ENVIRONMENT_MODIFICATION, which is how the build-tree dependency directories
# (libOMCDLL -> libOpenModelicaCompiler -> libOpenModelicaRuntimeC / libomcgc /
# toolchain runtime) are put on the loader path.
if(BUILD_TESTING AND CMAKE_VERSION VERSION_GREATER_EQUAL "3.22")
  add_executable(verify_libOMCDLL test/verify_libOMCDLL.c)
  target_compile_features(verify_libOMCDLL PRIVATE c_std_99)
  add_dependencies(verify_libOMCDLL OMCDLL OpenModelicaCompiler)
  if(NOT WIN32)
    target_link_libraries(verify_libOMCDLL PRIVATE ${CMAKE_DL_LIBS})
  endif()
  if(_omcdll_rt_dir)
    set_target_properties(verify_libOMCDLL PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${_omcdll_rt_dir})
  endif()

  add_test(NAME omcCAPI-libOMCDLL-usable
           COMMAND verify_libOMCDLL $<TARGET_FILE:OMCDLL>)

  # Directories holding libOMCDLL and its (transitive) shared-library deps. In
  # the build tree these are scattered; the install tree co-locates them in bin/.
  set(_omcdll_dep_dirs
      $<TARGET_FILE_DIR:OMCDLL>
      $<TARGET_FILE_DIR:OpenModelicaCompiler>
      $<TARGET_FILE_DIR:OpenModelicaRuntimeC>
      $<TARGET_FILE_DIR:omcgc>)
  if(WIN32)
    omc_get_msys_prefix(_omcdll_msys_prefix)
    list(APPEND _omcdll_dep_dirs "${_omcdll_msys_prefix}/bin")
    set(_omcdll_path_var PATH)
  elseif(APPLE)
    set(_omcdll_path_var DYLD_LIBRARY_PATH)
  else()
    set(_omcdll_path_var LD_LIBRARY_PATH)
  endif()

  set(_omcdll_env_mod "")
  foreach(_dir IN LISTS _omcdll_dep_dirs)
    list(APPEND _omcdll_env_mod "${_omcdll_path_var}=path_list_prepend:${_dir}")
  endforeach()

  # omc loads its builtin .mo files from ../lib/omc relative to
  # libOpenModelicaCompiler; the OpenModelicaCompiler target copies them into
  # <build>/lib/omc as a POST_BUILD step, so point OPENMODELICAHOME one level
  # above the dll directory.
  set_tests_properties(omcCAPI-libOMCDLL-usable PROPERTIES
    LABELS omcCAPI
    # verify_libOMCDLL exits 77 when it cannot load the library at all (a missing
    # runtime dir is an environment problem, not an ABI regression).
    SKIP_RETURN_CODE 77
    ENVIRONMENT_MODIFICATION "${_omcdll_env_mod}"
    ENVIRONMENT "OPENMODELICAHOME=$<TARGET_FILE_DIR:OpenModelicaCompiler>/..")
endif()
