cmake_minimum_required (VERSION 2.6)

project(${ReduceDAEName})

include_directories (${OMCCAPI_INCLUDE_DIR})

add_library(${ReduceDAEName} STATIC com/ModelicaCompiler.cpp ReduceDAESettings.cpp Ranking.cpp Reduction.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${ReduceDAEName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${ReduceDAEName} ${Boost_LIBRARIES} ${OMCCAPI_LIB} )
add_precompiled_header(${ReduceDAEName} Include/Core/Modelica.h)

install(FILES "ReduceDAESettings.xml" DESTINATION share/omc/runtime/cpp/config)
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/ReduceDAE/IReduceDAE.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/ReduceDAE/IReduceDAESettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/ReduceDAE/ReduceDAESettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/ReduceDAE/Ranking.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/ReduceDAE/Reduction.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/ReduceDAE/com/ModelicaCompiler.h
  DESTINATION include/omc/omsicpp/Core/ReduceDAE)





