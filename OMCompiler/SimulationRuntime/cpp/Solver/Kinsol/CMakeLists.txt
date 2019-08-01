cmake_minimum_required(VERSION 2.8.9)

project(${KinsolName})
IF(DGESV_FOUND)
 include_directories (${DGESV_INCLUDE_DIR})
 add_library(${KinsolName} Kinsol.cpp KinsolLapack.cpp KinsolSettings.cpp FactoryExport.cpp  ${DGESV_SRCS})
 target_link_libraries(${KinsolName}  ${SolverName}  ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES}  ${ModelicaName} )
ELSE()
 #use full Lapack
 add_library(${KinsolName} Kinsol.cpp KinsolLapack.cpp KinsolSettings.cpp FactoryExport.cpp)
 target_link_libraries(${KinsolName}  ${SolverName}  ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES}  ${ModelicaName} ${LAPACK_LIBRARIES})
ENDIF(DGESV_FOUND)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${KinsolName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${KinsolName} Include/Core/Modelica.h)
target_link_libraries(${KinsolName}  ${SolverName}  ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES}  ${ModelicaName} )


install(FILES $<TARGET_PDB_FILE:${KinsolName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${KinsolName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/Kinsol.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/KinsolSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/Kinsol)
