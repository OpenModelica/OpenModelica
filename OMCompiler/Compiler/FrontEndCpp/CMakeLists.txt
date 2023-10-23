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

# For now assume mingw32-make is available here. It should be because it is what we use
# to compile generated simulation code on Windows when omc is issuing the compilation.
# This variable will substitute @ Autoconf.make.
# Autoconf.make inturn (at least so far) is used to issue compilation of FMU sources.
# For anything that is issued through SystemCall use this mingw32-make (instead of just 'make'
# which is the MSYS make.) since the latter is not supposed to be used on Windows shells.
# (systemCall uses 'cmd \c' to issue commands.)
if (MINGW)
  set(OMC_MAKE_EXE "mingw32-make")
else()
  set(OMC_MAKE_EXE "make")
endif()

set(OMC_CMAKE_EXE "${CMAKE_COMMAND}")

if(MINGW)
  set(CONFIG_OS "Windows_NT")

  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread -lgfortran -lstdc++ ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -lopenblas -lm -lpthread ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-Wl,-Bstatic -lSimulationRuntimeFMI -Wl,-Bdynamic -lopenblas -lm -lpthread -lgfortran -lstdc++ ")

elseif(MSVC)
  set(CONFIG_OS "Windows_NT")

  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread -lgfortran -lstdc++ ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -lopenblas -lm -lpthread ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-Wl,-Bstatic -lSimulationRuntimeFMI -Wl,-Bdynamic -lopenblas -lm -lpthread -lgfortran -lstdc++ ")

elseif(APPLE)
  set(CONFIG_OS "OSX")

  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lomcgc -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-lSimulationRuntimeFMI -llapack -lblas -lm")

elseif(UNIX AND NOT APPLE)
  set(CONFIG_OS ${OMC_TARGET_SYSTEM_NAME})

  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -rdynamic")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -lstdc++ -rdynamic ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -rdynamic ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-lstdc++ -rdynamic ")

else()
   message(FATAL_ERROR "Unknow system for OpenModelica simulation code generation and compilation. OpenModelica does not know how to compile and simulate simulation code on this configuration.")
endif()
