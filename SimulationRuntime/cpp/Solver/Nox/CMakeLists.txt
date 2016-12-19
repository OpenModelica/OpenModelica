cmake_minimum_required(VERSION 2.8.9)

project(${NoxName})

add_library(${NoxName} Nox.cpp NoxSettings.cpp FactoryExport.cpp NoxLapackInterface.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${NoxName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${NoxName} Include/Core/Modelica.h)
target_link_libraries(${NoxName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${TRILINOS_LIBRARIES} )    #C:/OpenModelica/OMCompiler/SimulationRuntime/cpp/Solver/KLU/OMCppklu_static.lib
#target_link_libraries(${NoxName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${LAPACK_LIBRARIES} ${kluName})

install(TARGETS ${NoxName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Solver/Nox/Nox.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/Nox/NoxSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/Nox/FactoryExport.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/Nox/NoxLapackInterface.h
  DESTINATION include/omc/cpp/Solver/Nox)
