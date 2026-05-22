
project(SimRT_CPP)

# add_definitions(-DOMC_BUILD)

# CPP libs should be installed to in lib/<arch>/omc/cpp/ for now.
set(CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_LIBDIR}/cpp)
set(CMAKE_INSTALL_BINDIR ${CMAKE_INSTALL_LIBDIR})
# CPP headers are installed in include/omc/cpp for now.
set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/cpp)

set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME simrtcpp)



# Boost and a threading library are required for the CPP-runtime.
if(APPLE)
 # MacPorts installs the Boost configuration file in a non-standard location,
 # keep using the old FindBoost module for now.
 find_package(Boost COMPONENTS program_options filesystem REQUIRED)
elseif(CMAKE_VERSION VERSION_LESS "3.30")
 find_package(Boost COMPONENTS program_options filesystem REQUIRED)
else()
  find_package(Boost CONFIG COMPONENTS program_options filesystem REQUIRED)
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

if (Boost_FOUND)
get_linker_flag_from_library_target(Boost::program_options LINK_FLAG)
set(Boost_LIBRARIES_  ${LINK_FLAG})
get_linker_flag_from_library_target(Boost::filesystem LINK_FLAG)
set(Boost_LIBRARIES_ "${Boost_LIBRARIES_} ${LINK_FLAG}")

message(STATUS "using boost include for OMCompiler/SimulationRuntime/cpp runtime: ${Boost_INCLUDE_DIR}")
message(STATUS "Boost Libraries for OMCompiler/SimulationRuntime/cpp runtime implict/explicit: ${Boost_LIBRARIES} / ${Boost_LIBRARIES_}")
else()
message(FATAL_ERROR "Boost Libraries WERE NOT FOUND!")
endif()

# This should be defined for all CPP-runtime library compilations.
# Signifies that we are building the source code (instead of consuming, say the headers ...).
target_compile_definitions(OMCppConfig INTERFACE OMC_BUILD)


# Subdirectories
add_subdirectory(SimCoreFactory)
add_subdirectory(Core)
add_subdirectory(Solver)
add_subdirectory(FMU)
add_subdirectory(FMU2)


## This little function will give us the filename of the CPP runtime
## library given its alias.
function (omc_get_library_filename target_alias LIB_FILENAME)
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
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Include/
         TYPE INCLUDE)
