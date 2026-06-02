cmake_minimum_required(VERSION 3.5...4.3)

project(${RTEulerName})

add_library(${RTEulerName} RTEuler.cpp RTEulerSettings.cpp FactoryExport.cpp )

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${RTEulerName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
  if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${RTEulerName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
  endif(MSVC)
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries (${RTEulerName} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})


install(TARGETS ${RTEulerName} DESTINATION ${LIBINSTALLEXT})
