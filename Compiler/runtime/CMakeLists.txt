

IF(NOT IDL)
  FIND_PROGRAM(IDL idl DOC "Location of the idl executable"
               PATHS ENV OMDEV 
               PATH_SUFFIXES bin bin/mico)
  MESSAGE(STATUS "-- idl is " ${IDL})
ENDIF(NOT IDL)

INCLUDE_DIRECTORIES($ENV{OMDEV}/tools/rml/include/plain)
INCLUDE_DIRECTORIES(${CODEGENDIR})
INCLUDE_DIRECTORIES(${CODEGENDIR}/absyn_builder)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/lpsolve)

# custom command for idl
SET(IDL_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/omc_communication.cc ${CMAKE_CURRENT_BINARY_DIR}/omc_communication.h)
ADD_CUSTOM_COMMAND(OUTPUT ${IDL_OUTPUT}
                   COMMAND ${IDL} ${CMAKE_CURRENT_SOURCE_DIR}/omc_communication.idl  												  
                   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                   COMMENT "Generate omc_communication")

# target fuer OM_OUTPUT
ADD_CUSTOM_TARGET(omc_communication ALL DEPENDS ${IDL_OUTPUT})	

# Quellen und Header
SET(CORBASRC ${IDL_OUTPUT} omc_communication_impl.cpp corbaimpl.cpp)
SET(SRC	rtopts.c socketimpl.c printimpl.c systemimpl.c settingsimpl.c dynload.c SimulationResults.c)
SET(CPPSRC  unitparser.cpp unitparserext.cpp ptolemyio.cpp daeext.cpp ErrorMessage.cpp errorext.cpp
            optmanager.cpp systemimplmisc.cpp ${CORBASRC})
SET(OBJ ${SRC} ${CPPSRC})
	
# Bibliothek
link_directories(${OMCTRUNCHOME}/Compiler/runtime/lpsolve/lib/win32)
#add_definitions(/O2 /Ot /D "WIN32" /D "NDEBUG" /D "_LIB"  /D "_MBCS" /FD /EHsc /MT /GS- /W2 /c /TP)
add_definitions(/MT)
ADD_LIBRARY(runtime ${OBJ})
TARGET_LINK_LIBRARIES(runtime optimized lpsolve55 debug lpsolve55d)
add_dependencies(runtime ${MOCH_ALL})
