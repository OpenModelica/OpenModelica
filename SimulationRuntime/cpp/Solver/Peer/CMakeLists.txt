cmake_minimum_required (VERSION 2.8.6)

project(${PeerName})

# add the solver default implementation library
add_library(${PeerName}_static STATIC Peer.cpp PeerSettings.cpp FactoryExport.cpp)

SET(PEER_COMPILE_DEFINITIONS "")
IF(OPENMP_FOUND)
	SET(PEER_COMPILE_DEFINITIONS "USE_OPENMP")
ELSE(OPENMP_FOUND)
	SET(OpenMP_CXX_FLAGS "")
ENDIF(OPENMP_FOUND)

add_precompiled_header(${PeerName}_static Include/Core/Modelica.h )
install (TARGETS ${PeerName}_static DESTINATION ${LIBINSTALLEXT})

add_library(${PeerName} SHARED Peer.cpp PeerSettings.cpp FactoryExport.cpp  )
target_link_libraries (${PeerName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES})

IF(OPENMP_FOUND)
	set_target_properties(${PeerName}_static PROPERTIES LINK_FLAGS ${OpenMP_CXX_FLAGS})
	set_target_properties(${PeerName} PROPERTIES LINK_FLAGS ${OpenMP_CXX_FLAGS})
ENDIF(OPENMP_FOUND)

set_target_properties(${PeerName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;${PEER_COMPILE_DEFINITIONS}")
set_target_properties(${PeerName} PROPERTIES COMPILE_DEFINITIONS "${PEER_COMPILE_DEFINITIONS}")

if (UNIX)
	set_target_properties(${PeerName}_static PROPERTIES COMPILE_FLAGS "-fPIC ${OpenMP_CXX_FLAGS}")
	set_target_properties(${PeerName} PROPERTIES COMPILE_FLAGS "-fPIC ${OpenMP_CXX_FLAGS}")
else(UNIX)
	set_target_properties(${PeerName}_static PROPERTIES COMPILE_FLAGS "${OpenMP_CXX_FLAGS}")
	set_target_properties(${PeerName} PROPERTIES COMPILE_FLAGS "${OpenMP_CXX_FLAGS}")
endif(UNIX)

add_precompiled_header(${PeerName} Include/Core/Modelica.h )

install (TARGETS ${PeerName} ${PeerName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/Peer/Peer.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Peer/FactoryExport.h
DESTINATION include/omc/cpp/Solver/Peer)
