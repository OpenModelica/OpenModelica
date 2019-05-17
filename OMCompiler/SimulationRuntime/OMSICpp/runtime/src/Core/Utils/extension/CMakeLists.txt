cmake_minimum_required(VERSION 2.8.9)

project(${ExtensionUtilitiesName})

add_library(${ExtensionUtilitiesName} measure_time.cpp measure_time_statistic.cpp measure_time_rdtsc.cpp measure_time_scorep.cpp logger.cpp)

if(NOT BOOST_STATIC_LINKING)
  target_link_libraries (${ExtensionUtilitiesName} ${Boost_LIBRARIES})
endif(NOT BOOST_STATIC_LINKING)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${ExtensionUtilitiesName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
  install(FILES $<TARGET_PDB_FILE:${ExtensionUtilitiesName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)



install(TARGETS ${ExtensionUtilitiesName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Utils/extension/measure_time.hpp
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Utils/extension/measure_time_statistic.hpp
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Utils/extension/measure_time_rdtsc.hpp
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Utils/extension/measure_time_scorep.hpp
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Utils/extension/barriers.hpp
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Utils/extension/logger.hpp
  DESTINATION include/omc/omsicpp/Core/Utils/extension)

#install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/utils.h
#         DESTINATION include/omc/omsicpp/Core/Utils/numeric)
#install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas.hpp
#         DESTINATION include/omc/omsicpp/Core/Utils/numeric/bindings)
#install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas.hpp
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/banded.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/hermitian.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/matrix.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/matrix_expression.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/matrix_proxy.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/matrix_sparse.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/scalar_vector.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/storage.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/symmetric.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/triangular.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/vector.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/vector_expression.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/vector_proxy.hpp>
#				${CMAKE_SOURCE_DIR}/Include/Core/Utils/numeric/bindings/ublas/vector_sparse.hpp>
 #        DESTINATION include/omc/omsicpp/Core/Utils/numeric/bindings/ublas)

if(PAPI_FOUND)
  add_library("${ExtensionUtilitiesName}_papi" SHARED measure_time_papi.cpp)

  if(NOT BOOST_STATIC_LINKING)
    target_link_libraries ("${ExtensionUtilitiesName}_papi" ${Boost_LIBRARIES})
  endif(NOT BOOST_STATIC_LINKING)

  install(TARGETS "${ExtensionUtilitiesName}_papi" DESTINATION ${LIBINSTALLEXT})

  install(FILES ${CMAKE_SOURCE_DIR}/Include/Core/Utils/extension/measure_time_papi.hpp
    DESTINATION include/omc/omsicpp/Core/Utils/extension)
endif(PAPI_FOUND)
