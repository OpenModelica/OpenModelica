cmake_minimum_required(VERSION 2.8.9)

project(${OMCFactoryName})

add_library(${OMCFactoryName} SHARED OMCFactory.cpp)
add_library(${OMCFactoryName}_static STATIC OMCFactory.cpp )
set_target_properties(${OMCFactoryName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")

include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR}/kinsol ${SUNDIALS_INCLUDE_DIR})

install (TARGETS ${OMCFactoryName}_static DESTINATION ${LIBINSTALLEXT})
install (TARGETS ${OMCFactoryName} DESTINATION ${LIBINSTALLEXT})

target_link_libraries(${OMCFactoryName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} ${ExtensionUtilitiesName})
add_precompiled_header(${OMCFactoryName}_static Include/Core/Modelica.h)
add_precompiled_header(${OMCFactoryName} Include/Core/Modelica.h)

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

		${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SolverVxWorksFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/LinSolverVxWorksFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/NonLinSolverVxWorksFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SystemVxWorksFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SolverSettingsVxWorksFactory.h
DESTINATION include/omc/cpp/SimCoreFactory/Policies)

install (FILES ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/OMCFactory/StaticOMCFactory.h DESTINATION include/omc/cpp/SimCoreFactory/OMCFactory/)
install (FILES ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/OMCFactory/OMCFactory.h DESTINATION include/omc/cpp/SimCoreFactory/OMCFactory/)
install (FILES ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/VxWorksFactory/VxWorksFactory.h DESTINATION include/omc/cpp/SimCoreFactory/VxWorksFactory/)
install (FILES ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/ObjectFactory.h DESTINATION include/omc/cpp/SimCoreFactory)
