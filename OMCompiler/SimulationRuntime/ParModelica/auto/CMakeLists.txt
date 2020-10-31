cmake_minimum_required(VERSION 3.14)

project(ParModelicaAuto)

find_package(Boost REQUIRED COMPONENTS graph chrono)

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
target_compile_definitions(ParModelicaAuto PRIVATE USE_FLOW_SCHEDULER)

add_executable(ParModelicaAutoTest)
target_sources(ParModelicaAutoTest PRIVATE test_task_graph.cpp)
target_link_libraries(ParModelicaAutoTest ParModelicaAuto ParModelicaAuto)
