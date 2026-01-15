cmake_minimum_required(VERSION 3.5)

project(${ExtensionUtilitiesName})

add_library(${ExtensionUtilitiesName} measure_time.cpp measure_time_statistic.cpp measure_time_rdtsc.cpp measure_time_scorep.cpp logger.cpp)

if(NOT BOOST_STATIC_LINKING)
  target_link_libraries (${ExtensionUtilitiesName} ${Boost_LIBRARIES})
endif(NOT BOOST_STATIC_LINKING)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${ExtensionUtilitiesName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

install(FILES $<TARGET_PDB_FILE:${ExtensionUtilitiesName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${ExtensionUtilitiesName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Core/Utils/extension/measure_time.hpp
  ${CMAKE_SOURCE_DIR}/Core/Utils/extension/measure_time_statistic.hpp
  ${CMAKE_SOURCE_DIR}/Core/Utils/extension/measure_time_rdtsc.hpp
  ${CMAKE_SOURCE_DIR}/Core/Utils/extension/measure_time_scorep.hpp
  ${CMAKE_SOURCE_DIR}/Core/Utils/extension/barriers.hpp
  ${CMAKE_SOURCE_DIR}/Core/Utils/extension/logger.hpp
  DESTINATION include/omc/cpp/Core/Utils/extension)

if(PAPI_FOUND)
  add_library("${ExtensionUtilitiesName}_papi" SHARED measure_time_papi.cpp)

  if(NOT BOOST_STATIC_LINKING)
    target_link_libraries ("${ExtensionUtilitiesName}_papi" ${Boost_LIBRARIES})
  endif(NOT BOOST_STATIC_LINKING)

  install(TARGETS "${ExtensionUtilitiesName}_papi" DESTINATION ${LIBINSTALLEXT})

  install(FILES ${CMAKE_SOURCE_DIR}/Core/Utils/extension/measure_time_papi.hpp
    DESTINATION include/omc/cpp/Core/Utils/extension)
endif(PAPI_FOUND)
