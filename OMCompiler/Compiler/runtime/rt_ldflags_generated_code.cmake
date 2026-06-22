# Link flags appended to generated simulation / FMU code, by platform. Single
# source of truth shared by the C runtime build (runtime/CMakeLists.txt) and the
# Rust port: rust_omc.cmake forwards these to the cargo build as OMC_RT_LDFLAGS_*
# env vars, which Autoconf.rs reads via option_env!. Only platform booleans are
# used, so this can be included before omc_config_unix.cmake.
if(MINGW OR MSVC)
  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread -lgfortran -lstdc++ ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -lopenblas -lm -lpthread ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-Wl,-Bstatic -lSimulationRuntimeFMI -Wl,-Bdynamic -lopenblas -lm -lpthread -lgfortran -lstdc++ ")
elseif(APPLE)
  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lomcgc -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-lSimulationRuntimeFMI -llapack -lblas -lm")
elseif(UNIX)
  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lomcgc -llapack -lblas -lm -lpthread -rdynamic")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -lzlib -llapack -lblas -lm -ldl -lpthread -lgfortran -lstdc++ -rdynamic ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -llapack -lblas -lm -lpthread -rdynamic ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-Wl,-Bstatic -lSimulationRuntimeFMI -Wl,-Bdynamic -llapack -lblas -lm -ldl -lpthread -lgfortran -lstdc++ -rdynamic ")
else()
  message(FATAL_ERROR "Unknown system for OpenModelica simulation code generation and compilation. OpenModelica does not know how to compile and simulate simulation code on this configuration.")
endif()
