cmake_minimum_required (VERSION 2.6)

project(${ModelicaName})

add_library(${ModelicaName} SHARED ModelicaSystem.cpp )

target_link_libraries (${ModelicaName}  ${SystemName} ${ModelicaExternalCName}  ${MathName})


GET_TARGET_PROPERTY(libModelicaSystem ${ModelicaName} LOCATION)
GET_FILENAME_COMPONENT(libModelicaSystemNameExt ${libModelicaSystem} EXT)

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  include(CheckTypeSize)
  check_type_size("void*" SIZEOF_VOID_P BUILTIN_TYPES_ONLY)
  set(LINUX_LIB_DL "-ldl")
  if(${SIZEOF_VOID_P} MATCHES 8)
    set(FMI_ARCH_DIR "linux64")
  else(${SIZEOF_VOID_P} MATCHES 8)
    set(FMI_ARCH_DIR "linux32")
  endif(${SIZEOF_VOID_P} MATCHES 8)
endif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")

if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
  set(LINUX_LIB_DL "")
  set(FMI_ARCH_DIR "win32")
endif(${CMAKE_SYSTEM_NAME} MATCHES "Windows")

#GET_TARGET_PROPERTY(libboostSystem ${Boost_SYSTEM_LIBRARY} LOCATION)
#GET_FILENAME_COMPONENT(libboostSystemNAME ${libboostSystem} NAME)
#set(Boost_SYSTEM_LIBRARY_NAME ${libboostSystemNAME})

set (BOOST_INCLUDE ${Boost_INCLUDE_DIRS})
set (BOOST_LIBS ${Boost_LIBRARY_DIRS})
set (MODELICA_SYSTEM_LIB_EXT ${libModelicaSystemNameExt})
 configure_file (
  "ModelicaConfig.inc.in"
  "${PROJECT_BINARY_DIR}/ModelicaConfig.inc"
  )



install (FILES

				${PROJECT_BINARY_DIR}/ModelicaConfig.inc
				DESTINATION include/omc/cpp)


install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/HistoryImpl.h  ${CMAKE_SOURCE_DIR}/Include/Core/Modelica.h DESTINATION include/omc/cpp)
install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/Policies/TextfileWriter.h DESTINATION include/omc/cpp/Core/DataExchange/Policies)
#if(REDUCE_DAE)
#install (FILES Policies/BufferReaderWriter.h DESTINATION include/omc/cpp/policies)
#endif()



