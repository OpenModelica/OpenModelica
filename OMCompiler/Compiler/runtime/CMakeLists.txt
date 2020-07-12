



set(OMC_RUNTIIME_SOURCES Error_omc.cpp)
add_library(omcruntime ${OMC_RUNTIIME_SOURCES})
target_link_libraries(omcruntime PUBLIC OpenModelicaRuntimeC)
target_include_directories(omcruntime PUBLIC ${OMCompiler_SOURCE_DIR}/Compiler) #for OpenModelicaBootstrappingHeader.h :/
target_include_directories(omcruntime PUBLIC ${SimulationRuntimeC_SOURCE_DIR}) #for openmodelica.h :/

# CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

# # Global Variables
# IF(NOT OMCTRUNCHOME)
#   SET(OMCTRUNCHOME ${CMAKE_CURRENT_SOURCE_DIR}/../../)
# ENDIF (NOT OMCTRUNCHOME)

# IF(NOT IDL)
#   FIND_PROGRAM(IDL idl DOC "Location of the idl executable"
#                PATHS ENV OMDEV
#                PATH_SUFFIXES bin bin/mico)
#   MESSAGE(STATUS "-- idl is " ${IDL})
# ENDIF(NOT IDL)

# if(MSVC)
#   add_definitions(-DOMC_NO_THREADS -D_CRT_SECURE_NO_WARNINGS)
# endif(MSVC)
# INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})
# INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/lpsolve)
# INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c)
# INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/meta)
# INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/util)
# INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/3rdParty/gc/include)

# # custom command for idl
# IF(IDL)
# SET(IDL_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/omc_communication.cc ${CMAKE_CURRENT_BINARY_DIR}/omc_communication.h)
# ADD_CUSTOM_COMMAND(OUTPUT ${IDL_OUTPUT}
#                    COMMAND ${IDL} ${CMAKE_CURRENT_SOURCE_DIR}/omc_communication.idl
#                    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
#                    COMMENT "Generate omc_communication")

# # target fuer OM_OUTPUT
# ADD_CUSTOM_TARGET(omc_communication ALL DEPENDS ${IDL_OUTPUT})
# ENDIF(IDL)

# # Quellen und Header
# SET(CORBASRC ${IDL_OUTPUT} omc_communication_impl.cpp corbaimpl.cpp)
# SET(SRC socketimpl.c printimpl.c systemimpl.c settingsimpl.c SimulationResults.c)
# SET(CPPSRC  unitparser.cpp unitparserext.cpp ptolemyio.cpp Dynload.cpp BackendDAEEXT.cpp ErrorMessage.cpp errorext.cpp
#             systemimplmisc.cpp ${CORBASRC} serializer.cpp OMSimulator_omc.c)
# SET(OBJ ${SRC} ${CPPSRC})

# IF(WIN32)
#   SET(platform_libs optimized mico2313 debug mico2313d)
# ELSE(WIN32)
#   SET(platform_libs mico2.3.13)
# ENDIF(WIN32)
# link_directories(${OMCTRUNCHOME}/Compiler/runtime/lpsolve/lib/win32)

# # Library runtime
# ADD_LIBRARY(runtime ${OBJ})
# TARGET_LINK_LIBRARIES(runtime sendData c_runtime ${platform_libs} optimized lpsolve55 debug lpsolve55d)
# IF(MOCH_codegen_ALL)
# add_dependencies(runtime ${MOCH_codegen_ALL})
# ENDIF(MOCH_codegen_ALL)
