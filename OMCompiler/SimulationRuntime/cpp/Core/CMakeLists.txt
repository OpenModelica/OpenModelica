
macro(target_public_headers TARGET)
    set_target_properties(${TARGET} PROPERTIES PUBLIC_HEADER "${ARGN}")
endmacro()

set(SCOREP_INCLUDE_ ".")
set(Boost_INCLUDE_ ".")
set(Boost_LIBS_ ".")
set(LAPACK_LIBS_ ".")
set(LAPACK_LIBRARIES_ "-llapack -lblas")
set(SYSTEM_CFLAGS ${SYSTEM_CFLAGS} "-DOMC_BUILD -fPIC -DUSE_THREAD")

configure_file(Modelica/ModelicaLibraryConfig_gcc.inc.in ${CMAKE_CURRENT_BINARY_DIR}/ModelicaLibraryConfig_gcc.inc)
configure_file(Modelica/ModelicaConfig_gcc.inc.in ${CMAKE_CURRENT_BINARY_DIR}/ModelicaConfig_gcc.inc)

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

target_link_options(OMCppDataExchange PRIVATE  -Wl,--no-undefined)

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

target_link_options(OMCppModelica PRIVATE  -Wl,--no-undefined)

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

target_link_options(OMCppMath PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppMath)

# OMCppMath_static
add_library(OMCppMath_static STATIC)
add_library(omc::simrt::cpp::core::math::static ALIAS OMCppMath_static)

target_sources(OMCppMath_static PRIVATE ${OMC_SIMRT_CPP_CORE_MATH_SOURCES})

target_compile_definitions(OMCppMath_static PRIVATE -DRUNTIME_STATIC_LINKING)

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

target_link_options(OMCppSolver PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppSolver)

# OMCppSolver_static
add_library(OMCppSolver_static STATIC)
add_library(omc::simrt::cpp::core::solver::static ALIAS OMCppSolver_static)

target_sources(OMCppSolver_static PRIVATE ${OMC_SIMRT_CPP_CORE_SOLVER_SOURCES})

target_compile_definitions(OMCppSolver_static PRIVATE -DRUNTIME_STATIC_LINKING)

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

target_link_options(OMCppExtensionUtilities PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppExtensionUtilities)

# OMCppExtensionUtilities_static
add_library(OMCppExtensionUtilities_static STATIC)
add_library(omc::simrt::cpp::core::utils::extension::static ALIAS OMCppExtensionUtilities_static)

target_sources(OMCppExtensionUtilities_static PRIVATE ${OMC_SIMRT_CPP_CORE_UTILS_EXTENSIONS_SOURCES})

target_compile_definitions(OMCppExtensionUtilities_static PRIVATE -DRUNTIME_STATIC_LINKING)

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

target_link_options(OMCppModelicaUtilities PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppModelicaUtilities)

# OMCppModelicaUtilities_static
add_library(OMCppModelicaUtilities_static STATIC)
add_library(omc::simrt::cpp::core::utils::modelica::static ALIAS OMCppModelicaUtilities_static)

target_sources(OMCppModelicaUtilities_static PRIVATE ${OMC_SIMRT_CPP_CORE_UTILS_MODELICA_SOURCES})

target_compile_definitions(OMCppModelicaUtilities_static PRIVATE -DRUNTIME_STATIC_LINKING)

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

target_link_options(OMCppSimController PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppSimController)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN SimController/*.h
)


#####################################################################################################
find_package(Boost COMPONENTS filesystem REQUIRED)

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

target_link_options(OMCppSimulationSettings PRIVATE  -Wl,--no-undefined)

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

target_link_options(OMCppSystem PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppSystem)

# OMCppSystem_static
add_library(OMCppSystem_static STATIC)
add_library(omc::simrt::cpp::core::system::static ALIAS OMCppSystem_static)

target_sources(OMCppSystem_static PRIVATE ${OMC_SIMRT_CPP_CORE_SYSTEM_SOURCES})

target_compile_definitions(OMCppSystem_static PRIVATE -DRUNTIME_STATIC_LINKING)

target_link_libraries(OMCppSystem_static PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppSystem_static)
##

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN System/*.h
)


