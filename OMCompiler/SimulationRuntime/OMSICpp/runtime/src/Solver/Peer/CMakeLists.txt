cmake_minimum_required(VERSION 2.8.9)

project(${PeerName})

add_library(${PeerName} Peer.cpp PeerSettings.cpp FactoryExport.cpp)

set(PEER_COMPILE_DEFINITIONS "")
if(OPENMP_FOUND)
  set(PEER_COMPILE_DEFINITIONS "USE_OPENMP")
else(OPENMP_FOUND)
  set(OpenMP_CXX_FLAGS "")
endif(OPENMP_FOUND)

target_link_libraries(${PeerName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES})

if(OPENMP_FOUND)
  set_target_properties(${PeerName} PROPERTIES LINK_FLAGS ${OpenMP_CXX_FLAGS})
endif(OPENMP_FOUND)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${PeerName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
  install(FILES $<TARGET_PDB_FILE:${PeerName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)

set_target_properties(${PeerName} PROPERTIES COMPILE_DEFINITIONS "${PEER_COMPILE_DEFINITIONS}")
set_target_properties(${PeerName} PROPERTIES COMPILE_FLAGS "${OpenMP_CXX_FLAGS}")

add_precompiled_header(${PeerName} runtime/include/Core/Modelica.h)



install(TARGETS ${PeerName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/Peer/Peer.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/Peer/FactoryExport.h
  DESTINATION include/omc/omsicpp/Solver/Peer)
