set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/c/ParModelica/auto)

set(PARMODAUTO_SOURCES om_pm_equation.cpp om_pm_interface.cpp om_pm_model.cpp pm_utility.cpp pm_runtime_config.cpp)

add_library(ParModelicaAuto STATIC)
target_sources(ParModelicaAuto PRIVATE ${PARMODAUTO_SOURCES})
if(WIN32)
  target_sources(ParModelicaAuto PRIVATE pm_win_timer.cpp)
else()
  target_sources(ParModelicaAuto PRIVATE pm_posix_timer.cpp)
endif()


target_link_libraries(ParModelicaAuto PUBLIC omc::simrt::runtime)
target_link_libraries(ParModelicaAuto PUBLIC omc::3rd::tbb)

# The parmodauto scheduler (flow vs level) is now selected at run time via the
# parmodScheduler flag, so both schedulers are always compiled in (no -DUSE_*_SCHEDULER).

# For now, disable deprecation warning from the json reader. We do not plan to update any time soon.
if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
  target_compile_options(ParModelicaAuto PRIVATE -Wno-deprecated-declarations)
endif()

install(TARGETS ParModelicaAuto)
install(FILES om_pm_interface.hpp
        TYPE INCLUDE)
