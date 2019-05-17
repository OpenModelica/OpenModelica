cmake_minimum_required(VERSION 2.8.9)

project(${MathName})

add_library(${MathName} ArrayOperations.cpp Functions.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${MathName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
   install(FILES $<TARGET_PDB_FILE:${MathName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${MathName} ${Boost_LIBRARIES} ${UMFPACK_LIB} ${LAPACK_LIBRARIES} ${ModelicaName})
add_precompiled_header(${MathName} runtime/include/Core/Modelica.h )



install(TARGETS ${MathName} DESTINATION ${LIBINSTALLEXT})
install(FILES ${CMAKE_SOURCE_DIR}/runtime/include/Core/Math/Functions.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Math/ArrayOperations.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Math/Utility.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Math/Constants.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Math/SparseMatrix.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Math/ILapack.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Math/OMAPI.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Math/Array.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Math/ArraySlice.h
  DESTINATION include/omc/omsicpp/Core/Math)
