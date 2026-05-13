cmake_minimum_required(VERSION 3.5)

project(${EulerName})

if(DGESV_FOUND)
  include_directories (${DGESV_INCLUDE_DIR})
  add_library(${EulerName} Euler.cpp EulerSettings.cpp FactoryExport.cpp  ${DGESV_SRCS})
  target_link_libraries (${EulerName} ${SolverName} ${Boost_LIBRARIES} )
else()
  #use full Lapack
  add_library(${EulerName} Euler.cpp EulerSettings.cpp FactoryExport.cpp)
  target_link_libraries (${EulerName} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
endif(DGESV_FOUND)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${EulerName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
  if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${EulerName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
  endif(MSVC)
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${EulerName} runtime/include/Core/Modelica.h )
target_link_libraries (${EulerName} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})




install(TARGETS ${EulerName} DESTINATION ${LIBINSTALLEXT})
