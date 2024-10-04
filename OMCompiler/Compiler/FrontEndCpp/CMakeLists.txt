# Existence checks
#################################################################################################

# Some example portability checks. Add more just like this if you need more.
# e.g this will define HAVE_TIME_H 1 if found or HAVE_TIME_H 0 otherwise
omc_check_header_exists_and_define(time.h)
# e.g this will define HAVE_CTIME_S 1 if found or HAVE_CTIME_S 0 otherwise
omc_check_function_exists_and_define(ctime_s)
omc_check_function_exists_and_define(ctime_r)


add_subdirectory(Absyn)

# Libraries
##################################################################################################
set(OMC_FRONTEND_CPP_SOURCES
    Inst.cpp
    MetaModelica.cpp
    Path.cpp
    Prefixes.cpp
    Restriction.cpp
    SourceInfo.cpp)

# ######################################################################################################################
# Library: omcruntime
add_library(omcfrontendcpp STATIC)
add_library(omc::compiler::frontendcpp ALIAS omcfrontendcpp)

target_sources(omcfrontendcpp PRIVATE ${OMC_FRONTEND_CPP_SOURCES})

target_link_libraries(omcfrontendcpp PUBLIC omc::compiler::frontendcpp::absyn)
target_link_libraries(omcfrontendcpp PUBLIC omc::simrt::runtime)

target_include_directories(omcfrontendcpp PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

set(CC ${CMAKE_C_COMPILER})
set(CXX ${CMAKE_CXX_COMPILER})

if (MSVC)

else()
  target_compile_options(omcfrontendcpp PRIVATE -Wall -Wextra -Wpedantic)
endif()
