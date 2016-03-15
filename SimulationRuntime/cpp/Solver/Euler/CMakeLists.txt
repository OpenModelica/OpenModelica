cmake_minimum_required(VERSION 2.8.9)

project(${EulerName})

add_library(${EulerName} Euler.cpp EulerSettings.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${EulerName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
add_precompiled_header(${EulerName} Include/Core/Modelica.h )
target_link_libraries (${EulerName} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})

install(TARGETS ${EulerName} DESTINATION ${LIBINSTALLEXT})
install(FILES "config/EulerSettings.xml" DESTINATION share/omc/runtime/cpp/config)
