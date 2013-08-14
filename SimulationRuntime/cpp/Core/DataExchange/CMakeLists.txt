cmake_minimum_required (VERSION 2.6)

project(${DataExchangeName})

add_library(${DataExchangeName} SHARED SimData.cpp FactoryExport.cpp )
target_link_libraries (${DataExchangeName} ${Boost_LIBRARIES}  )

add_library(${DataExchangeName}_static STATIC SimData.cpp  )
target_link_libraries (${DataExchangeName}_static ${Boost_LIBRARIES})
if (UNIX)
set_target_properties(${DataExchangeName}_static PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

install (TARGETS ${DataExchangeName} DESTINATION lib/omc/${LIBINSTALLEXT})
install (TARGETS ${DataExchangeName}_static DESTINATION lib/omc/${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/IHistory.h
				${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/ISimVar.h
				${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/SimData.h
  DESTINATION include/omc/cpp/Core/DataExchange)






