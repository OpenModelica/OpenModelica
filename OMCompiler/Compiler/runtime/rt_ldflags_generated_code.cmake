# Link flags appended to generated simulation / FMU code, by platform. Single
# source of truth shared by the C runtime build (runtime/CMakeLists.txt) and the
# Rust port: rust_omc.cmake forwards these to the cargo build as OMC_RT_LDFLAGS_*
# env vars, which Autoconf.rs reads via option_env!. Only platform booleans are
# used, so this can be included before omc_config_unix.cmake.
if(MINGW OR MSVC)
  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread")
  # -Wl,--allow-multiple-definition (MinGW only): SimulationRuntimeC.dll and OpenModelicaRuntimeC.dll
  # both re-export the same __imp_ import descriptors; recent binutils ld errors on the duplicates,
  # so keep the first (they resolve to the same DLL symbol). MSVC builds OpenModelicaRuntimeC static
  # and uses link.exe, so it neither hits the issue nor understands this flag.
  if(MINGW)
    set(RT_LDFLAGS_GENERATED_CODE_SIM " -Wl,--allow-multiple-definition -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread -lgfortran -lstdc++ ")
  else()
    set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread -lgfortran -lstdc++ ")
  endif()
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
