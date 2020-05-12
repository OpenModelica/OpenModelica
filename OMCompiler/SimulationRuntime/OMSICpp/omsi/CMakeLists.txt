#Cpp Simulation  for OpenModelica Simulation Interface (OMSI)
PROJECT(omsicpp)
SET(CMAKE_VERBOSE_MAKEFILE ON)


include_directories ("${CMAKE_SOURCE_DIR}/omsi/include")
include_directories ("${CMAKE_SOURCE_DIR}/omsi/src")
# FMI 2.0 Header
include_directories ("${CMAKE_SOURCE_DIR}/../../3rdParty/FMIL/ThirdParty/FMI/default/FMI2")

  MESSAGE(STATUS "OMSI Library:")
  MESSAGE(STATUS "${OMSIBASE_LIB}")
#Removed this library because the omsicpp code generation is skipped at the moment which used this library

	#add_library(${OSUName} STATIC src/fmi2/omsi_fmi2_me.cpp src/fmi2/detail/omsi_fmi2_log.cpp src/fmi2/detail/omsi_fmi2_wrapper.cpp  src/omsi_factory.cpp src/omsi_global_settings.cpp  )
	#IF(WIN32)
	#target_link_libraries(${OSUName}  ${OMCFactoryName} ${SimControllerName} ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} wsock32 ws2_32)
	#ELSE(WIN32)
		#target_link_libraries(${OSUName} ${OMCFactoryName}  ${SimControllerName} ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} 	${Boost_LIBRARIES} ${CMAKE_DL_LIBS})
	#ENDIF(WIN32)


	#install(TARGETS ${OSUName} DESTINATION ${LIBINSTALLEXT})


IF(BUILD_SHARED_LIBS)

    MESSAGE(STATUS "Set rpath for omsu simulation executable " ${LIB_OMC})
    set(CMAKE_INSTALL_RPATH "$ORIGIN/../${LIB_OMC}/omsicpp/:$ORIGIN")
    SET(CMAKE_BUILD_WITH_INSTALL_RPATH ON)
    #SET (CMAKE_EXE_LINKER_FLAGS
    #"${CMAKE_EXE_LINKER_FLAGS} -Wl,-rpath,'$$ORIGIN/../${LibFolderExtension}/'" )
    add_executable(${OSUSimName} src/omsi.cpp )

    IF(WIN32)
		target_link_libraries(${OSUSimName} ${OMCFactoryName} ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} wsock32 ws2_32)
        #Removed this library because the omsicpp code generation is skipped at the moment which used this library
			#target_link_libraries(${OSUName}  ${OMCFactoryName} ${SimControllerName} ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} wsock32 ws2_32)
	ELSE(WIN32)
		target_link_libraries(${OSUSimName} ${OMCFactoryName} ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS})
        #Removed this library because the omsicpp code generation is skipped at the moment which used this library
			#target_link_libraries(${OSUName} ${OMCFactoryName}  ${SimControllerName} ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} )
    ENDIF(WIN32)
#Removed this library because the omsicpp code generation is skipped at the moment which used this library
	#set_target_properties(${OSUName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")

IF(MSVC)
install(FILES $<TARGET_PDB_FILE:${OSUSimName}> DESTINATION bin OPTIONAL)
#install(FILES $<TARGET_PDB_FILE:${OSUName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)

install(TARGETS ${OSUSimName} DESTINATION bin)
ENDIF(BUILD_SHARED_LIBS)





