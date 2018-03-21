cmake_minimum_required(VERSION 2.8.9)

project(${KinsolName})

add_library(${KinsolName} Kinsol.cpp KinsolLapack.cpp KinsolSettings.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${KinsolName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${KinsolName} Include/Core/Modelica.h)
target_link_libraries(${KinsolName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${LAPACK_LIBRARIES}  ${ModelicaName} )   


install(FILES $<TARGET_PDB_FILE:${KinsolName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${KinsolName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/Kinsol.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/KinsolSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/Kinsol)
