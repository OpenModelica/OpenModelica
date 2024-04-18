set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/ParModelica/auto)

find_package(Boost COMPONENTS graph chrono REQUIRED)

set(PARMODAUTO_SOURCES om_pm_equation.cpp om_pm_interface.cpp om_pm_model.cpp pm_utility.cpp)

add_library(ParModelicaAuto STATIC)
target_sources(ParModelicaAuto PRIVATE ${PARMODAUTO_SOURCES})
if(WIN32)
  target_sources(ParModelicaAuto PRIVATE pm_win_timer.cpp)
else()
  target_sources(ParModelicaAuto PRIVATE pm_posix_timer.cpp)
endif()


target_link_libraries(ParModelicaAuto PUBLIC omc::simrt::runtime)
target_link_libraries(ParModelicaAuto PUBLIC omc::3rd::tbb)
target_link_libraries(ParModelicaAuto PUBLIC Boost::graph)

target_compile_definitions(ParModelicaAuto PRIVATE USE_FLOW_SCHEDULER)

# For now, disable deprecation warning from the json reader. We do not plan to update any time soon.
if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
  target_compile_options(ParModelicaAuto PRIVATE -Wno-deprecated-declarations)
endif()

# add_executable(ParModelicaAutoTest)
# target_sources(ParModelicaAutoTest PRIVATE test_task_graph.cpp)
# target_link_libraries(ParModelicaAutoTest PRIVATE ParModelicaAuto)


install(TARGETS ParModelicaAuto)
install(FILES om_pm_interface.hpp
        TYPE INCLUDE)