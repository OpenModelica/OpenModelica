cmake_minimum_required(VERSION 3.5)

project(${MathName})

add_library(${MathName} ArrayOperations.cpp Functions.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${MathName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${MathName} ${Boost_LIBRARIES} ${UMFPACK_LIB} ${LAPACK_LIBRARIES} ${ModelicaName})
add_precompiled_header(${MathName} Core/Modelica.h )

install(FILES $<TARGET_PDB_FILE:${MathName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${MathName} DESTINATION ${LIBINSTALLEXT})
install(FILES ${CMAKE_SOURCE_DIR}/Core/Math/Functions.h
  ${CMAKE_SOURCE_DIR}/Core/Math/ArrayOperations.h
  ${CMAKE_SOURCE_DIR}/Core/Math/Utility.h
  ${CMAKE_SOURCE_DIR}/Core/Math/Constants.h
  ${CMAKE_SOURCE_DIR}/Core/Math/SparseMatrix.h
  ${CMAKE_SOURCE_DIR}/Core/Math/ILapack.h
  ${CMAKE_SOURCE_DIR}/Core/Math/OMAPI.h
  ${CMAKE_SOURCE_DIR}/Core/Math/Array.h
  ${CMAKE_SOURCE_DIR}/Core/Math/ArraySlice.h
  DESTINATION include/omc/cpp/Core/Math)
