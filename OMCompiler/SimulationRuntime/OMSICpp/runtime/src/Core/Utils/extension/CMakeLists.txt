cmake_minimum_required(VERSION 3.10...4.3)

project(${ExtensionUtilitiesName})

add_library(${ExtensionUtilitiesName} measure_time.cpp measure_time_statistic.cpp measure_time_rdtsc.cpp measure_time_scorep.cpp logger.cpp)


if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${ExtensionUtilitiesName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
  if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${ExtensionUtilitiesName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
  endif(MSVC)
endif(NOT BUILD_SHARED_LIBS)



install(TARGETS ${ExtensionUtilitiesName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Utils/extension/measure_time.hpp
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Utils/extension/measure_time_statistic.hpp
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Utils/extension/measure_time_rdtsc.hpp
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Utils/extension/measure_time_scorep.hpp
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Utils/extension/barriers.hpp
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Utils/extension/logger.hpp
  DESTINATION include/omc/omsicpp/Core/Utils/extension)


if(PAPI_FOUND)
  add_library("${ExtensionUtilitiesName}_papi" SHARED measure_time_papi.cpp)


  install(TARGETS "${ExtensionUtilitiesName}_papi" DESTINATION ${LIBINSTALLEXT})

  install(FILES ${OMSICPP_SOURCE_DIR}/Include/Core/Utils/extension/measure_time_papi.hpp
    DESTINATION include/omc/omsicpp/Core/Utils/extension)
endif(PAPI_FOUND)
