CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${SimControllerName})
include_directories (${OMCCAPI_INCLUDE_DIR})


if(USE_ZEROMQ)
    ADD_DEFINITIONS(-DUSE_ZEROMQ)
    add_library(${SimControllerName}
      Configuration.cpp
      FactoryExport.cpp
      Initialization.cpp
      SimController.cpp
      SimManager.cpp
      threading/Communicator.cpp
      threading/ProgressThread.cpp
      threading/SimulationThread.cpp
      threading/ToZeroMQEvent.cpp
    )
    message (STATUS "Using ZMQ library ${ZeroMQ_LIBRARY} in SimController" )
else(USE_ZEROMQ)
    message (STATUS "Using ZMQ library disabled")
    add_library(${SimControllerName}
      Configuration.cpp
      FactoryExport.cpp
      Initialization.cpp
      SimController.cpp
      SimManager.cpp
    )
endif(USE_ZEROMQ)



if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SimControllerName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
 install(FILES $<TARGET_PDB_FILE:${SimControllerName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)
if(REDUCE_DAE)
target_link_libraries(${SimControllerName} ${OMCFactoryName} ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} ${ReduceDAEName} )
else(REDUCE_DAE)
if(USE_ZEROMQ)
        #target_link_libraries(${SimControllerName} ${OMCFactoryName} ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} ${ZeroMQ_LIBRARY}  )
        target_link_libraries(${SimControllerName} ${OMCFactoryName} ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} libzmq  )
else(USE_ZEROMQ)
        target_link_libraries(${SimControllerName} ${OMCFactoryName} ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS}  )
endif(USE_ZEROMQ)

endif(REDUCE_DAE)
add_precompiled_header(${SimControllerName} runtime/include/Core/Modelica.h)



install(TARGETS ${SimControllerName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimController/ISimData.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimController/ISimController.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimController/SimController.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimController/SimManager.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimController/SimController.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimController/SimManager.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimController/Configuration.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimController/Initialization.h
  DESTINATION include/omc/omsicpp/Core/SimController)
