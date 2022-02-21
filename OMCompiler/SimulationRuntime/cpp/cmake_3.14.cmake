
project(SimRT_CPP)

add_definitions(-DOMC_BUILD)

# CPP libs should be installed to in lib/<arch>/omc/cpp/ for now.
set(CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_LIBDIR}/cpp)
# CPP headers are installed in include/omc/cpp for now.
set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/cpp)



# An interface library for providing common include directories for all the CPP libs.
add_library(OMCppConfig INTERFACE)
add_library(omc::simrt::cpp::config ALIAS OMCppConfig)

target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_BINARY_DIR})
target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/Include)


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
omc_get_library_filename(omc::simrt::cpp::solver::kinsol KINSOL_LIB)
omc_get_library_filename(omc::simrt::cpp::solver::newton NEWTON_LIB)
# omc_get_library_filename(omc::simrt::cpp::core::utils::extension EXTENSIONUTILITIES_LIB)
omc_get_library_filename(omc::simrt::cpp::core::simcontroller SIMCONTROLLER_LIB)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/LibrariesConfig.h.in ${CMAKE_CURRENT_BINARY_DIR}/LibrariesConfig.h)


install(FILES ${CMAKE_CURRENT_BINARY_DIR}/LibrariesConfig.h
        TYPE INCLUDE)

# This folder contains only one file right now. Something should be done about it.
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Include/
         TYPE INCLUDE)
