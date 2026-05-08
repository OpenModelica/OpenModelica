cmake_minimum_required(VERSION 3.14)
set(CMAKE_VERBOSE_MAKEFILE ON)

# OMSI base simulation runtime
project(OMSIBASE)

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

# Fallback for "standalone" makefile build
# TODO: Remove when switching to CMake build
if(NOT TARGET omc::3rd::FMIL::expat)
  find_library(LIB_EXPAT NAMES expat libexpat
    PATHS ${OMBUILDDIR}/lib/omc ${CMAKE_CURRENT_SOURCE_DIR}/../../3rdParty/FMIL/build/ExpatEx/)
  if(NOT LIB_EXPAT)
    message(FATAL_ERROR "Could not find expat library")
  endif()
endif()

target_link_libraries(${OSUBaseName}
  PUBLIC OMSIBaseSimulationRuntime ${OMSISolverName} ${CMAKE_DL_LIBS})
if(TARGET omc::3rd::FMIL::expat)
  target_link_libraries(${OSUBaseName} PUBLIC omc::3rd::FMIL::expat)
else()
  target_link_libraries(${OSUBaseName} PUBLIC ${LIB_EXPAT})
endif()
if(WIN32)
  target_link_libraries(${OSUBaseName} PRIVATE wsock32 ws2_32)
endif()

install(TARGETS ${OSUBaseName}
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION ${LIBINSTALLEXT}
  ARCHIVE DESTINATION ${LIBINSTALLEXT})

# Fallback for "standalone" makefile build
# TODO: Remove when switching to CMake build
if(NOT TARGET omc::3rd::FMIL::expat)
  install(FILES ${LIB_EXPAT} DESTINATION ${CMAKE_INSTALL_LIBDIR})
endif()

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
