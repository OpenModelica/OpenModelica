cmake_minimum_required(VERSION 2.8.9)

project(${RK12Name})
# add the solver default implementation library

add_library(${RK12Name}_static STATIC RK12.cpp RK12Settings.cpp FactoryExport.cpp )
add_precompiled_header(${RK12Name}_static Include/Core/Modelica.h )
set_target_properties(${RK12Name}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

add_library(${RK12Name} SHARED RK12.cpp RK12Settings.cpp FactoryExport.cpp )
add_precompiled_header(${RK12Name} Include/Core/Modelica.h )

target_link_libraries (${RK12Name} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} )

install (TARGETS ${RK12Name} ${RK12Name}_static DESTINATION ${LIBINSTALLEXT})
install (FILES "config/RK12Settings.xml" DESTINATION share/omc/runtime/cpp/config)
