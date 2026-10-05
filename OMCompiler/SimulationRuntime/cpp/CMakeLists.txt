# The C++ simulation runtime.
#
# Builds the OMCpp* libraries (shared and _static variants) that the generated
# C++ simulation code and the C++ FMUs link against. The subdirectories added at
# the bottom hold the actual targets; everything here is the shared setup they
# all inherit through the OMCppConfig interface library
# (omc::simrt::cpp::config): include directories and the compile definitions
# below.
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
