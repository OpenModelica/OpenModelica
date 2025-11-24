CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${EulerName})

IF(DGESV_FOUND)
 include_directories (${DGESV_INCLUDE_DIR})
 add_library(${EulerName} Euler.cpp EulerSettings.cpp FactoryExport.cpp  ${DGESV_SRCS})
 target_link_libraries (${EulerName} ${SolverName} ${Boost_LIBRARIES} )
ELSE()
 #use full Lapack
 add_library(${EulerName} Euler.cpp EulerSettings.cpp FactoryExport.cpp)
 target_link_libraries (${EulerName} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
ENDIF(DGESV_FOUND)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${EulerName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
 install(FILES $<TARGET_PDB_FILE:${EulerName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${EulerName} runtime/include/Core/Modelica.h )
target_link_libraries (${EulerName} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})





install(TARGETS ${EulerName} DESTINATION ${LIBINSTALLEXT})
