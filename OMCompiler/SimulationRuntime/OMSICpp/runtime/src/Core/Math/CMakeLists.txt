cmake_minimum_required(VERSION 3.5)

project(${MathName})

add_library(${MathName} ArrayOperations.cpp Functions.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${MathName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
  if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${MathName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
  endif(MSVC)
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${MathName} ${Boost_LIBRARIES} ${UMFPACK_LIB} ${LAPACK_LIBRARIES} ${ModelicaName})
add_precompiled_header(${MathName} runtime/include/Core/Modelica.h )



install(TARGETS ${MathName} DESTINATION ${LIBINSTALLEXT})
install(FILES ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Math/Functions.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Math/ArrayOperations.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Math/Utility.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Math/Constants.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Math/SparseMatrix.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Math/ILapack.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Math/OMAPI.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Math/Array.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Math/ArraySlice.h
  DESTINATION include/omc/omsicpp/Core/Math)
