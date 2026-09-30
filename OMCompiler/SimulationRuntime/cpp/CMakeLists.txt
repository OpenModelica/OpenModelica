# The C++ simulation runtime.
#
# Builds the OMCpp* libraries (shared and _static variants) that the generated
# C++ simulation code and the C++ FMUs link against. The subdirectories added at
# the bottom hold the actual targets; everything here is the shared setup they
# all inherit through the OMCppConfig interface library
# (omc::simrt::cpp::config): include directories, Boost, and the compile
# definitions below.
#
# Compile definitions applied to every C++ runtime library:
#     OMC_BUILD    we are building the runtime, not consuming its headers
#     USE_LOGGER   enable the runtime logger, see Core/Utils/extension/logger.hpp
#
# The generated model code has to be compiled with the same definitions. They are
# collected in SYSTEM_CFLAGS (Core/CMakeLists.txt) and written into
# ModelicaConfig_gcc.inc, which the makefile of a generated model includes.

project(SimRT_CPP)

# add_definitions(-DOMC_BUILD)

# CPP libs should be installed to in lib/<arch>/omc/cpp/ for now.
set(CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_LIBDIR}/cpp)
set(CMAKE_INSTALL_BINDIR ${CMAKE_INSTALL_LIBDIR})
# CPP headers are installed in include/omc/cpp for now.
set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/cpp)

set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME simrtcpp)

# Coverage instrumentation (-DOM_ENABLE_COVERAGE=ON), applied directory-wide so
# every target defined here and in every add_subdirectory() below is covered.
# See cmake/modules/OpenModelicaCoverage.cmake.
if(OM_ENABLE_COVERAGE)
  add_compile_options(${OM_COVERAGE_COMPILE_OPTIONS})
  add_link_options(--coverage)
endif()

# Boost and a threading library are required for the CPP-runtime.
if(OM_FETCH_BOOST)
  # Built into this project by cmake/OMCBoost.cmake.
  set(Boost_FOUND TRUE)
else()
  # FindBoost was removed in CMake 4.0, Boost >= 1.70 ships its own
  # BoostConfig.cmake. Try CONFIG first (works everywhere when a config
  # exists, e.g. Homebrew/MacPorts), fall back to the FindBoost module on
  # older CMake/Boost combos. Do not branch on CMAKE_VERSION or APPLE:
  # whether CONFIG mode succeeds depends on the Boost installation, not
  # on the CMake version.
  find_package(Boost CONFIG COMPONENTS program_options filesystem QUIET)
  if(NOT Boost_FOUND)
    find_package(Boost COMPONENTS program_options filesystem REQUIRED)
  endif()
  # BoostConfig.cmake (CONFIG mode) does not set Boost_INCLUDE_DIR /
  # Boost_LIBRARY_DIRS, while the FindBoost module does. Normalize both
  # cases by extracting the dirs from the imported targets whenever the
  # variables are still empty, so the generated ModelicaConfig_gcc.inc can
  # always pass -I/-L to model builds.
  if(NOT Boost_INCLUDE_DIR)
    foreach(_t IN ITEMS Boost::headers Boost::boost Boost::filesystem)
      if(TARGET ${_t})
        get_target_property(_boost_inc ${_t} INTERFACE_INCLUDE_DIRECTORIES)
        if(_boost_inc AND NOT _boost_inc STREQUAL "_boost_inc-NOTFOUND")
          list(GET _boost_inc 0 Boost_INCLUDE_DIR)
          if(Boost_INCLUDE_DIR)
            break()
          endif()
        endif()
      endif()
    endforeach()
  endif()
  if(Boost_INCLUDE_DIR AND NOT Boost_INCLUDE_DIRS)
    set(Boost_INCLUDE_DIRS "${Boost_INCLUDE_DIR}")
  endif()
  if(NOT Boost_LIBRARY_DIRS)
    foreach(_comp IN ITEMS filesystem program_options)
      if(TARGET Boost::${_comp})
        foreach(_cfg IN ITEMS RELEASE "" DEBUG RELWITHDEBINFO MINSIZEREL)
          # On Windows a shared Boost target's IMPORTED_LOCATION is the DLL
          # in bin/; the link -L dir must come from IMPORTED_IMPLIB (lib/).
          if(_cfg STREQUAL "")
            get_target_property(_loc Boost::${_comp} IMPORTED_IMPLIB)
            if(NOT _loc OR _loc STREQUAL "_loc-NOTFOUND")
              get_target_property(_loc Boost::${_comp} IMPORTED_LOCATION)
            endif()
          else()
            get_target_property(_loc Boost::${_comp} IMPORTED_IMPLIB_${_cfg})
            if(NOT _loc OR _loc STREQUAL "_loc-NOTFOUND")
              get_target_property(_loc Boost::${_comp} IMPORTED_LOCATION_${_cfg})
            endif()
          endif()
          if(_loc AND NOT _loc STREQUAL "_loc-NOTFOUND")
            get_filename_component(Boost_LIBRARY_DIRS "${_loc}" DIRECTORY)
            break()
          endif()
        endforeach()
        if(Boost_LIBRARY_DIRS)
          break()
        endif()
      endif()
    endforeach()
  endif()
  if(Boost_LIBRARY_DIRS AND NOT Boost_LIBRARY_DIR)
    set(Boost_LIBRARY_DIR "${Boost_LIBRARY_DIRS}")
  endif()
endif()

find_package(Threads REQUIRED)

# An interface library for providing common include directories and other settings
# for all the CPP-runtime libraries.
add_library(OMCppConfig INTERFACE)
add_library(omc::simrt::cpp::config ALIAS OMCppConfig)

# Make the current source directory, current binary directory (contains generated files), and
# the Include/ directory available to all libraries that link to OMCppConfig (which means all CPP-runtime libs)
target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_BINARY_DIR})
target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/Include)

# Make boost headers transitively available to all CPP-runtime libraries
# (note that they all link to 'OMCppConfig' a.k.a 'omc::simrt::cpp::config')
target_link_libraries(OMCppConfig INTERFACE Boost::boost)

function(get_linker_flag_from_library_target TARGET OUT_VAR)
  # An in-project Boost (OM_FETCH_BOOST) has no IMPORTED_LOCATION.
  get_target_property(aliased ${TARGET} ALIASED_TARGET)
  if(aliased)
    set(TARGET ${aliased})
  endif()
  get_target_property(imported ${TARGET} IMPORTED)
  if(NOT imported)
    get_target_property(lib_base ${TARGET} OUTPUT_NAME)
    if(NOT lib_base)
      set(lib_base ${TARGET})
    endif()
    set(${OUT_VAR} "-l${lib_base}" PARENT_SCOPE)
    return()
  endif()

  # Get the actual library file path
  get_target_property(lib_location ${TARGET} IMPORTED_LOCATION)

  if(NOT lib_location)
    # Try debug/release specific
    get_target_property(lib_location ${TARGET} IMPORTED_LOCATION_RELEASE)
    if(NOT lib_location)
      get_target_property(lib_location ${TARGET} IMPORTED_LOCATION_DEBUG)
    endif()
  endif()

  if(lib_location)
    # Get just the filename
    get_filename_component(lib_name ${lib_location} NAME)

    # Strip off prefix and suffix to get the library name
    # Handle Unix libraries (libfoo.so, libfoo.a)
    if(lib_name MATCHES "^lib(.+)\\.(a|so\\.?[0-9.]*|dylib\\.?[0-9.]*|dll|lib)$")
      set(lib_base ${CMAKE_MATCH_1})
    # Handle Windows libraries (foo.lib)
    elseif(lib_name MATCHES "^(.+)\\.lib$")
      set(lib_base ${CMAKE_MATCH_1})
    else()
      set(lib_base ${lib_name})
    endif()

    set(${OUT_VAR} "-l${lib_base}" PARENT_SCOPE)
  else()
    message(WARNING "Could not find library location for ${TARGET}")
    set(${OUT_VAR} "" PARENT_SCOPE)
  endif()
endfunction()

if(Boost_FOUND)
  if(OM_FETCH_BOOST)
    # OMCppOMCFactory is a static library, so the generated model is what resolves
    # boost::program_options and boost::filesystem. Install them beside the OMCpp*
    # libraries under stable names; the upstream ones carry a toolset/version tag.
    set(_omc_boost_po ${CMAKE_STATIC_LIBRARY_PREFIX}omc_boost_program_options${CMAKE_STATIC_LIBRARY_SUFFIX})
    set(_omc_boost_fs ${CMAKE_STATIC_LIBRARY_PREFIX}omc_boost_filesystem${CMAKE_STATIC_LIBRARY_SUFFIX})
    install(FILES $<TARGET_FILE:boost_program_options>
            DESTINATION ${CMAKE_INSTALL_LIBDIR} RENAME ${_omc_boost_po})
    install(FILES $<TARGET_FILE:boost_filesystem>
            DESTINATION ${CMAKE_INSTALL_LIBDIR} RENAME ${_omc_boost_fs})
    if(MSVC)
      # link.exe takes file names, not -l
      set(Boost_LIBRARIES_ "${_omc_boost_po} ${_omc_boost_fs}")
    else()
      set(Boost_LIBRARIES_ "-lomc_boost_program_options -lomc_boost_filesystem")
    endif()
  else()
    get_linker_flag_from_library_target(Boost::program_options LINK_FLAG)
    set(Boost_LIBRARIES_ ${LINK_FLAG})
    get_linker_flag_from_library_target(Boost::filesystem LINK_FLAG)
    set(Boost_LIBRARIES_ "${Boost_LIBRARIES_} ${LINK_FLAG}")
  endif()

  message(STATUS "using boost include for OMCompiler/SimulationRuntime/cpp runtime: ${Boost_INCLUDE_DIR}")
  message(STATUS "Boost Libraries for OMCompiler/SimulationRuntime/cpp runtime implict/explicit: ${Boost_LIBRARIES} / ${Boost_LIBRARIES_}")
else()
  message(FATAL_ERROR "Boost Libraries WERE NOT FOUND!")
endif()

# This should be defined for all CPP-runtime library compilations.
# Signifies that we are building the source code (instead of consuming, say the headers ...).
target_compile_definitions(OMCppConfig INTERFACE OMC_BUILD)

# Enable the runtime logger. Without it every LOGGER_WRITE in
# Core/Utils/extension/logger.hpp expands to nothing, so a simulation prints no
# -lv output whatsoever (no solver statistics, no warnings about unrecognized
# simulation flags). The generated model code is compiled with the same define,
# handed to its makefile as USE_LOGGER in ModelicaConfig_gcc.inc; the two must
# agree, so keep this in sync with USE_LOGGER_ in Core/CMakeLists.txt.
target_compile_definitions(OMCppConfig INTERFACE USE_LOGGER)


# Subdirectories
add_subdirectory(SimCoreFactory)
add_subdirectory(Core)
add_subdirectory(Solver)
add_subdirectory(FMU)
add_subdirectory(FMU2)
add_subdirectory(FMU3)


## This little function will give us the filename of the CPP runtime
## library given its alias.
function(omc_get_library_filename target_alias LIB_FILENAME)
  get_target_property(LIB_FILENAME_LOCAL ${target_alias} ALIASED_TARGET)
  set(${LIB_FILENAME} ${CMAKE_SHARED_LIBRARY_PREFIX}${LIB_FILENAME_LOCAL}${CMAKE_SHARED_LIBRARY_SUFFIX} PARENT_SCOPE)
endfunction(omc_get_library_filename)

## Get the actual output filenames of the CPP runtime shared libs
## This are to be used in LibrariesConfig.h for the purpose of loading the
## libs at simulation time using their file name.
omc_get_library_filename(omc::simrt::cpp::core::system SYSTEM_LIB)
omc_get_library_filename(omc::simrt::cpp::core::dataexchange DATAEXCHANGE_LIB)
omc_get_library_filename(omc::simrt::cpp::core::math MATH_LIB)
omc_get_library_filename(omc::simrt::cpp::core::simsettings SETTINGSFACTORY_LIB)
omc_get_library_filename(omc::simrt::cpp::core::solver SOLVER_LIB)

omc_get_library_filename(omc::simrt::cpp::solver::cvode CVODE_LIB)
omc_get_library_filename(omc::simrt::cpp::solver::dassl DASSL_LIB)
omc_get_library_filename(omc::simrt::cpp::solver::dgesvsolver DGESVSOLVER_LIB)
omc_get_library_filename(omc::simrt::cpp::solver::ida IDA_LIB)
omc_get_library_filename(omc::simrt::cpp::solver::kinsol KINSOL_LIB)
omc_get_library_filename(omc::simrt::cpp::solver::newton NEWTON_LIB)
omc_get_library_filename(omc::simrt::cpp::core::simcontroller SIMCONTROLLER_LIB)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/LibrariesConfig.h.in ${CMAKE_CURRENT_BINARY_DIR}/LibrariesConfig.h)


install(FILES ${CMAKE_CURRENT_BINARY_DIR}/LibrariesConfig.h
        TYPE INCLUDE)

# This folder contains only one file right now. Something should be done about it.
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Include/
        TYPE INCLUDE)
