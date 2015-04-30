cmake_minimum_required (VERSION 2.8.6)

project(${PeerName})

# add the solver default implementation library
IF(RUNTIME_STATIC_LINKING)
	add_library(${PeerName}_static STATIC Peer.cpp PeerSettings.cpp FactoryExport.cpp  )
	install (TARGETS ${PeerName}_static DESTINATION ${LIBINSTALLEXT})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${PeerName} SHARED Peer.cpp PeerSettings.cpp FactoryExport.cpp  )
	target_link_libraries (${PeerName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES})
	add_precompiled_header(${PeerName} Include/Core/Modelica.h )
    install (TARGETS ${PeerName} DESTINATION ${LIBINSTALLEXT})
ENDIF(RUNTIME_STATIC_LINKING)

IF(RUNTIME_STATIC_LINKING)
  install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/Peer/Peer.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Peer/FactoryExport.h
           DESTINATION include/omc/cpp/Solver/Peer)
ENDIF(RUNTIME_STATIC_LINKING)
