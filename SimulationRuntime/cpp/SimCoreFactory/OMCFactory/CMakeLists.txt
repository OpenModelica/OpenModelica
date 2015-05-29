cmake_minimum_required (VERSION 2.8.6)

project(${OMCFactoryName})

add_library(${OMCFactoryName}_static STATIC OMCFactory.cpp StaticOMCFactory.cpp)
include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR}/kinsol ${SUNDIALS_INCLUDE_DIR})
install (TARGETS ${OMCFactoryName}_static DESTINATION ${LIBINSTALLEXT})
if (UNIX)
	set_target_properties(${OMCFactoryName}_static PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)
target_link_libraries(${OMCFactoryName}_static ${Boost_LIBRARIES} ${CMAKE_DL_LIBS})
add_precompiled_header(${OMCFactoryName}_static Include/Core/Modelica.h)

install (FILES
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/FactoryConfig.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/FactoryPolicy.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/LinSolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/NonLinSolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SystemOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SolverSettingsOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/StaticSolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/StaticLinSolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/StaticNonLinSolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/StaticSystemOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/StaticSolverSettingsOMCFactory.h
DESTINATION include/omc/cpp/SimCoreFactory/Policies)

install (FILES ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/OMCFactory/StaticOMCFactory.h DESTINATION include/omc/cpp/SimCoreFactory/OMCFactory/)
install (FILES ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/OMCFactory/OMCFactory.h DESTINATION include/omc/cpp/SimCoreFactory/OMCFactory/)
install (FILES ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/ObjectFactory.h DESTINATION include/omc/cpp/SimCoreFactory)
