

#####################################################################################################
# Configure and generate the files 'ModelicaLibraryConfig_gcc.inc' and 'ModelicaConfig_gcc.inc'
# These files tell the CPP code generator what name to use and where to find the necessary
# libraries for the generated simulation code. This does not cover all variables that are used
# or set by the old CPP-runtime build system. However, these seem to be enough to build things
# on Linux and Windows with OMDev.

# SCOREP_INCLUDE_ is added to the compilation command-line of the generated code (in the Makefiles).
# It is not clear why this one is chosen among the many others to be explicitly added to the generated
# compilation code. It needs to be set to a valid directory resembling path.
set(SCOREP_INCLUDE_ ".")

# The boost libraries and headers are expected to be in the system directories.
# For MSVC this needs to be adjusted. However, it is not clear which approach we are
# taking for MSVC yet. So leave it like this until we decide.
set(Boost_INCLUDE_ ".")
# This is supposwed to signify the directory where the boost libraries can be found (for -L ...)
set(Boost_LIBS_ ".")
# The actual boost libraries needed to be linked.
set(Boost_LIBRARIES_ "-lboost_program_options -lboost_filesystem")

# Lapack libs are also expected to be in the system directories.
set(LAPACK_LIBS_ ".")
if(UNIX)
  set(LAPACK_LIBRARIES_ "-llapack -lblas")
  set(LINUX_LIB_DL "-ldl")
endif()

# The thread library flag (can be something like -lpthreads for example). Let CMake decide the value.
set(CPPTHREADS_LIBRARY_FLAG ${CMAKE_THREAD_LIBS_INIT})

# Some common flags for the generated simulation code. It is not clear why OMC_BUILD is defined
# by the old system. It is always defined for some reason. USE_THREAD means use the C++ standard
# library's thread library (instead of something like boost threads).
set(SYSTEM_CFLAGS ${SYSTEM_CFLAGS} "-DOMC_BUILD -DUSE_THREAD -fPIC")

# Configure the files.
configure_file(Modelica/ModelicaLibraryConfig_gcc.inc.in ${CMAKE_CURRENT_BINARY_DIR}/ModelicaLibraryConfig_gcc.inc)
configure_file(Modelica/ModelicaConfig_gcc.inc.in ${CMAKE_CURRENT_BINARY_DIR}/ModelicaConfig_gcc.inc)

# Install them during installtion. They end up in the appropriate include directory. Right now that is 'include/cpp'.
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/ModelicaLibraryConfig_gcc.inc
               ${CMAKE_CURRENT_BINARY_DIR}/ModelicaConfig_gcc.inc
         TYPE INCLUDE)



#####################################################################################################
# OMCppDataExchange
set(OMC_SIMRT_CPP_CORE_DATAEXCHANGE_SOURCES DataExchange/SimData.cpp
                                            DataExchange/FactoryExport.cpp
                                            DataExchange/XmlPropertyReader.cpp)

add_library(OMCppDataExchange SHARED)
add_library(omc::simrt::cpp::core::dataexchange ALIAS OMCppDataExchange)

target_sources(OMCppDataExchange PRIVATE ${OMC_SIMRT_CPP_CORE_DATAEXCHANGE_SOURCES})

target_link_libraries(OMCppDataExchange PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppDataExchange)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN DataExchange/*.h
)


#####################################################################################################
# OMCppModelica
set(OMC_SIMRT_CPP_CORE_MODELICA_SOURCES Modelica/Modelica.cpp)

add_library(OMCppModelica SHARED)
add_library(omc::simrt::cpp::core::modelica ALIAS OMCppModelica)

target_sources(OMCppModelica PRIVATE ${OMC_SIMRT_CPP_CORE_MODELICA_SOURCES})

target_link_libraries(OMCppModelica PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppModelica)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN Modelica.h
        PATTERN ModelicaDefine.h
        PATTERN DataExchange/Policies/TextfileWriter.h
        PATTERN DataExchange/Policies/MatfileWriter.h
        PATTERN DataExchange/Policies/BufferReaderWriter.h
)

#####################################################################################################
# OMCppMath
set(OMC_SIMRT_CPP_CORE_MATH_SOURCES Math/ArrayOperations.cpp
                                    Math/Functions.cpp
                                    Math/FactoryExport.cpp)

add_library(OMCppMath SHARED)
add_library(omc::simrt::cpp::core::math ALIAS OMCppMath)

target_sources(OMCppMath PRIVATE ${OMC_SIMRT_CPP_CORE_MATH_SOURCES})

target_link_libraries(OMCppMath PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppMath)

# OMCppMath_static
add_library(OMCppMath_static STATIC)
add_library(omc::simrt::cpp::core::math::static ALIAS OMCppMath_static)

target_sources(OMCppMath_static PRIVATE ${OMC_SIMRT_CPP_CORE_MATH_SOURCES})

target_compile_definitions(OMCppMath_static PRIVATE RUNTIME_STATIC_LINKING)

target_link_libraries(OMCppMath_static PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppMath_static)
##

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN Math/*.h
)


#####################################################################################################
# OMCppSolver
set(OMC_SIMRT_CPP_CORE_SOLVER_SOURCES Solver/SolverDefaultImplementation.cpp
                                      Solver/AlgLoopSolverDefaultImplementation.cpp
                                      Solver/SolverSettings.cpp
                                      Solver/SystemStateSelection.cpp
                                      Solver/FactoryExport.cpp
                                      Solver/SimulationMonitor.cpp)

add_library(OMCppSolver SHARED)
add_library(omc::simrt::cpp::core::solver ALIAS OMCppSolver)

target_sources(OMCppSolver PRIVATE ${OMC_SIMRT_CPP_CORE_SOLVER_SOURCES})

target_link_libraries(OMCppSolver PUBLIC omc::simrt::cpp::config)
target_link_libraries(OMCppSolver PUBLIC omc::simrt::cpp::core::math)

install(TARGETS OMCppSolver)

# OMCppSolver_static
add_library(OMCppSolver_static STATIC)
add_library(omc::simrt::cpp::core::solver::static ALIAS OMCppSolver_static)

target_sources(OMCppSolver_static PRIVATE ${OMC_SIMRT_CPP_CORE_SOLVER_SOURCES})

target_compile_definitions(OMCppSolver_static PRIVATE RUNTIME_STATIC_LINKING)

target_link_libraries(OMCppSolver_static PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppSolver_static)
##

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN Solver/*.h
)


#####################################################################################################
# OMCppExtensionUtilities
set(OMC_SIMRT_CPP_CORE_UTILS_EXTENSIONS_SOURCES Utils/extension/measure_time.cpp
                                     Utils/extension/measure_time_statistic.cpp
                                     Utils/extension/measure_time_rdtsc.cpp
                                     Utils/extension/measure_time_scorep.cpp
                                     Utils/extension/logger.cpp)

add_library(OMCppExtensionUtilities SHARED)
add_library(omc::simrt::cpp::core::utils::extension ALIAS OMCppExtensionUtilities)

target_sources(OMCppExtensionUtilities PRIVATE ${OMC_SIMRT_CPP_CORE_UTILS_EXTENSIONS_SOURCES})

target_link_libraries(OMCppExtensionUtilities PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppExtensionUtilities)

# OMCppExtensionUtilities_static
add_library(OMCppExtensionUtilities_static STATIC)
add_library(omc::simrt::cpp::core::utils::extension::static ALIAS OMCppExtensionUtilities_static)

target_sources(OMCppExtensionUtilities_static PRIVATE ${OMC_SIMRT_CPP_CORE_UTILS_EXTENSIONS_SOURCES})

target_compile_definitions(OMCppExtensionUtilities_static PRIVATE RUNTIME_STATIC_LINKING)

target_link_libraries(OMCppExtensionUtilities_static PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppExtensionUtilities_static)
##

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN Utils/extension/*.hpp
        PATTERN Utils/extension/impl/*.hpp
)


#####################################################################################################
# OMCppModelicaUtilities
set(OMC_SIMRT_CPP_CORE_UTILS_MODELICA_SOURCES Utils/Modelica/ModelicaUtilities.cpp
                                              Utils/Modelica/ModelicaSimulationError.cpp)

add_library(OMCppModelicaUtilities SHARED)
add_library(omc::simrt::cpp::core::utils::modelica ALIAS OMCppModelicaUtilities)

target_sources(OMCppModelicaUtilities PRIVATE ${OMC_SIMRT_CPP_CORE_UTILS_MODELICA_SOURCES})

target_link_libraries(OMCppModelicaUtilities PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppModelicaUtilities)

# OMCppModelicaUtilities_static
add_library(OMCppModelicaUtilities_static STATIC)
add_library(omc::simrt::cpp::core::utils::modelica::static ALIAS OMCppModelicaUtilities_static)

target_sources(OMCppModelicaUtilities_static PRIVATE ${OMC_SIMRT_CPP_CORE_UTILS_MODELICA_SOURCES})

target_compile_definitions(OMCppModelicaUtilities_static PRIVATE RUNTIME_STATIC_LINKING)

target_link_libraries(OMCppModelicaUtilities_static PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppModelicaUtilities_static)
##

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN Utils/Modelica/ModelicaSimulationError.h
)

#####################################################################################################
# OMCppSimController
set(OMC_SIMRT_CPP_CORE_SIMCONTROLLER_SOURCES SimController/Configuration.cpp
                                             SimController/FactoryExport.cpp
                                             SimController/Initialization.cpp
                                             SimController/SimController.cpp
                                             SimController/SimManager.cpp
                                             SimController/SimObjects.cpp)

add_library(OMCppSimController SHARED)
add_library(omc::simrt::cpp::core::simcontroller ALIAS OMCppSimController)

target_sources(OMCppSimController PRIVATE ${OMC_SIMRT_CPP_CORE_SIMCONTROLLER_SOURCES})

target_link_libraries(OMCppSimController PUBLIC omc::simrt::cpp::config)
target_link_libraries(OMCppSimController PUBLIC omc::simrt::cpp::simcorefactory::omcfactory)
target_link_libraries(OMCppSimController PUBLIC omc::simrt::cpp::core::utils::modelica)
target_link_libraries(OMCppSimController PUBLIC Boost::filesystem)

install(TARGETS OMCppSimController)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN SimController/*.h
)


#####################################################################################################
# OMCppSimulationSettings
set(OMC_SIMRT_CPP_CORE_SIM_SETTINGS_SOURCES SimulationSettings/GlobalSettings.cpp
                                            SimulationSettings/Factory.cpp
                                            SimulationSettings/FactoryExport.cpp)

add_library(OMCppSimulationSettings SHARED)
add_library(omc::simrt::cpp::core::simsettings ALIAS OMCppSimulationSettings)

target_sources(OMCppSimulationSettings PRIVATE ${OMC_SIMRT_CPP_CORE_SIM_SETTINGS_SOURCES})

target_link_libraries(OMCppSimulationSettings PUBLIC omc::simrt::cpp::config)
target_link_libraries(OMCppSimulationSettings PUBLIC omc::simrt::cpp::simcorefactory::omcfactory)
target_link_libraries(OMCppSimulationSettings PUBLIC Boost::filesystem)

install(TARGETS OMCppSimulationSettings)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN SimulationSettings/IGlobalSettings.h
        PATTERN SimulationSettings/ISettingsFactory.h
)


#####################################################################################################
# OMCppSystem
set(OMC_SIMRT_CPP_CORE_SYSTEM_SOURCES System/LinearAlgLoopDefaultImplementation.cpp
                                      System/NonLinearAlgLoopDefaultImplementation.cpp
                                      System/AlgLoopSolverFactory.cpp
                                      System/EventHandling.cpp
                                      System/DiscreteEvents.cpp
                                      System/ContinuousEvents.cpp
                                      System/SystemDefaultImplementation.cpp
                                      System/SimVars.cpp
                                      System/FactoryExport.cpp)

add_library(OMCppSystem SHARED)
add_library(omc::simrt::cpp::core::system ALIAS OMCppSystem)

target_sources(OMCppSystem PRIVATE ${OMC_SIMRT_CPP_CORE_SYSTEM_SOURCES})

target_link_libraries(OMCppSystem PUBLIC omc::simrt::cpp::config)
target_link_libraries(OMCppSystem PUBLIC omc::simrt::cpp::simcorefactory::omcfactory)
target_link_libraries(OMCppSystem PUBLIC Boost::filesystem)

install(TARGETS OMCppSystem)

# OMCppSystem_static
add_library(OMCppSystem_static STATIC)
add_library(omc::simrt::cpp::core::system::static ALIAS OMCppSystem_static)

target_sources(OMCppSystem_static PRIVATE ${OMC_SIMRT_CPP_CORE_SYSTEM_SOURCES})

target_compile_definitions(OMCppSystem_static PRIVATE RUNTIME_STATIC_LINKING)

target_link_libraries(OMCppSystem_static PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppSystem_static)
##

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN System/*.h
)


