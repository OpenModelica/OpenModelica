# includes
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../c)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../c/linearization)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../c/math-support)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../c/meta)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../c/meta/gc)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../c/ModelicaExternalC)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../c/simulation)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../c/util)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../c/simulation/libf2c)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../c/simulation/results)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../c/simulation/solver)

# Quellen und Header
SET(interactive_sources  omi_Calculation.cpp omi_Control.cpp omi_ResultManager.cpp
				 omi_ServiceInterface.cpp omi_Transfer.cpp socket.cpp thread.cpp)

SET(interactive_headers  omi_Calculation.h omi_Control.h omi_ResultManager.h
                         omi_ServiceInterface.h omi_Transfer.h socket.h thread.h)

# Library util
ADD_LIBRARY(interactive ${interactive_sources} ${interactive_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS interactive
		ARCHIVE DESTINATION lib)

INSTALL(FILES ${interactive_headers} DESTINATION include)
