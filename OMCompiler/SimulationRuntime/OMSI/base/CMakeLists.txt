cmake_minimum_required(VERSION 3.14)
SET(CMAKE_VERBOSE_MAKEFILE ON)

#OMSI base simulation runtime
PROJECT(OMSIBASE)

add_library(${OSUBaseName}
  src/omsi_event_helper.c
  src/omsi_getters_and_setters.c
  src/omsi_initialization.c
  src/omsi_input_json.c
  src/omsi_input_model_variables.c
  src/omsi_input_sim_data.c
  src/omsi_input_xml.c
  src/omsi_mmap.c
  src/omsi_posix_func.c
  src/omsi_solve_alg_system.c
  src/omsi_utils.c)

target_include_directories(${OSUBaseName} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")

set_target_properties(${OSUBaseName} PROPERTIES MACOSX_RPATH ON)

target_link_libraries(${OSUBaseName}
    PUBLIC OMSIBaseSimulationRuntime ${OMSISolverName} ${CMAKE_DL_LIBS} omc::3rd::FMIL::expat)
if(WIN32)
  target_link_libraries(${OSUBaseName} PRIVATE wsock32 ws2_32)
endif()

install(TARGETS ${OSUBaseName} DESTINATION ${LIBINSTALLEXT})

install(FILES
  include/omsi_event_helper.h
  include/omsi_getters_and_setters.h
  include/omsi_global.h
  include/omsi_initialization.h
  include/omsi_input_json.h
  include/omsi_input_model_variables.h
  include/omsi_input_sim_data.h
  include/omsi_input_xml.h
  include/omsi_mmap.h
  include/omsi_posix_func.h
  include/omsi_solve_alg_system.h
  include/omsi_utils.h
  include/uthash.h
  DESTINATION include/omc/omsi/base)
