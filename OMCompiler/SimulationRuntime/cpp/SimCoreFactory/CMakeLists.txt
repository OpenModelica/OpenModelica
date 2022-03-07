

#####################################################################################################
# OMCppOMCFactory
find_package(Boost COMPONENTS program_options filesystem REQUIRED)
find_package(Threads REQUIRED)


set(OMC_SIMRT_CPP_SIMCOREFACTORY_OMCFACTORY_SOURCES OMCFactory/OMCFactory.cpp)

add_library(OMCppOMCFactory SHARED)
add_library(omc::simrt::cpp::simcorefactory::omcfactory ALIAS OMCppOMCFactory)

target_sources(OMCppOMCFactory PRIVATE ${OMC_SIMRT_CPP_SIMCOREFACTORY_OMCFACTORY_SOURCES})

target_link_libraries(OMCppOMCFactory PUBLIC omc::simrt::cpp::config)
target_link_libraries(OMCppOMCFactory PUBLIC omc::simrt::cpp::core::utils::extension)
target_link_libraries(OMCppOMCFactory PUBLIC Boost::program_options)
target_link_libraries(OMCppOMCFactory PUBLIC Boost::filesystem)
target_link_libraries(OMCppOMCFactory PUBLIC Threads::Threads)
target_link_libraries(OMCppOMCFactory PUBLIC ${CMAKE_DL_LIBS})

if(WIN32)
  target_link_libraries(OMCppOMCFactory PUBLIC wsock32)
  target_link_libraries(OMCppOMCFactory PUBLIC ws2_32)
endif()

target_link_options(OMCppOMCFactory PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppOMCFactory)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN Policies/FactoryConfig.h
        PATTERN OMCFactory/OMCFactory.h
)

