cmake_minimum_required (VERSION 2.6)

project(${PeerName})

# add the solver default implementation library
IF(ANALYZATION_MODE)
	add_library(${PeerName} STATIC Peer.cpp PeerSettings.cpp FactoryExport.cpp  )
	target_link_libraries (${PeerName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBS})
ELSE(ANALYZATION_MODE)
	add_library(${PeerName} SHARED Peer.cpp PeerSettings.cpp FactoryExport.cpp  )
	target_link_libraries (${PeerName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES})
ENDIF(ANALYZATION_MODE)
#target_link_libraries( Euler ${Boost_serialization_LIBRARY})

install (TARGETS ${PeerName} DESTINATION lib/omc/${LIBINSTALLEXT})
#install (FILES "../Interfaces/EulerSettings.xml"
 # DESTINATION bin/config)

IF(ANALYZATION_MODE)
  install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/Peer/Peer.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Peer/FactoryExport.h
           DESTINATION include/omc/cpp/Solver/Peer)
ENDIF(ANALYZATION_MODE)
