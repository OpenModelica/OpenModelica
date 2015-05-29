cmake_minimum_required (VERSION 2.8.6)

project(${PeerName})

# add the solver default implementation library
add_library(${PeerName}_static STATIC Peer.cpp PeerSettings.cpp FactoryExport.cpp)
set_target_properties(${PeerName}_static PROPERTIES COMPILE_DEFINITIONS "DRUNTIME_STATIC_LINKING")
add_precompiled_header(${PeerName}_static Include/Core/Modelica.h )
install (TARGETS ${PeerName}_static DESTINATION ${LIBINSTALLEXT})

add_library(${PeerName} SHARED Peer.cpp PeerSettings.cpp FactoryExport.cpp  )
target_link_libraries (${PeerName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES})
add_precompiled_header(${PeerName} Include/Core/Modelica.h )

install (TARGETS ${PeerName} ${PeerName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/Peer/Peer.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Peer/FactoryExport.h
DESTINATION include/omc/cpp/Solver/Peer)
