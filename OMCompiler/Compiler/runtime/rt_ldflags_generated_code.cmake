# Link flags appended to generated simulation / FMU code, by platform. Single
# source of truth shared by the C runtime build (runtime/CMakeLists.txt) and the
# Rust port: rust_omc.cmake forwards these to the cargo build as OMC_RT_LDFLAGS_*
# env vars, which Autoconf.rs reads via option_env!. Only platform booleans are
# used, so this can be included before omc_config_unix.cmake.

# Only the MetaModelica runtime (_MMC) uses Boehm. A Modelica function library
# links the counted runtime; a MetaModelica one links omc's, as omc reads back
# what it built.
if(MSVC)
  # link.exe takes file names, not -l, and has no -lm/-lgfortran/-lstdc++.
  # OpenModelicaRuntimeC is static and already inside SimulationRuntimeC.dll.
  set(RT_LDFLAGS_GENERATED_CODE "OpenModelicaRuntimeC.lib libopenblas.lib pthreadVC3.lib")
  set(RT_LDFLAGS_GENERATED_CODE_MMC "OpenModelicaRuntimeMMC.lib omcgc.lib libopenblas.lib pthreadVC3.lib")
  # zlib for the minizip in fmilib, which FMU import links.
  set(RT_LDFLAGS_GENERATED_CODE_SIM "SimulationRuntimeC.lib zlib.lib libopenblas.lib pthreadVC3.lib")
  set(RT_LDFLAGS_GENERATED_CODE_SIM_RUST "SimulationRuntimeRust.lib zlib.lib libopenblas.lib pthreadVC3.lib")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU "libopenblas.lib pthreadVC3.lib")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "SimulationRuntimeFMI.lib libopenblas.lib pthreadVC3.lib")
elseif(MINGW)
  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lopenblas -lm -lpthread")
  set(RT_LDFLAGS_GENERATED_CODE_MMC " -lOpenModelicaRuntimeMMC -lomcgc -lopenblas -lm -lpthread")
  # -Wl,--allow-multiple-definition: SimulationRuntimeC.dll and OpenModelicaRuntimeC.dll
  # both re-export the same __imp_ import descriptors; recent binutils ld errors on the duplicates,
  # so keep the first (they resolve to the same DLL symbol).
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -Wl,--allow-multiple-definition -lSimulationRuntimeC -lOpenModelicaRuntimeC -lopenblas -lm -lpthread -lgfortran -lstdc++ ")
  set(RT_LDFLAGS_GENERATED_CODE_SIM_RUST " -Wl,--allow-multiple-definition -lSimulationRuntimeRust -lOpenModelicaRuntimeC -lopenblas -lm -lpthread -lgfortran -lstdc++ ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -lopenblas -lm -lpthread ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-Wl,-Bstatic -lSimulationRuntimeFMI -Wl,-Bdynamic -lopenblas -lm -lpthread -lgfortran -lstdc++ ")
elseif(APPLE)
  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_MMC " -lOpenModelicaRuntimeMMC -lomcgc -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SIM_RUST " -lSimulationRuntimeRust -lOpenModelicaRuntimeC -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-lSimulationRuntimeFMI -llapack -lblas -lm")
elseif(UNIX)
  # Alpine/musl only packages OpenBLAS, which does not provide an unversioned
  # libblas.so (only libopenblas.so, which bundles both BLAS and LAPACK), so
  # -lblas fails to link there. Fall back to -lopenblas when a standalone
  # libblas.so isn't available, same as the MinGW/MSVC branch above.
  find_library(OMC_SYSTEM_LIBBLAS_FOUND NAMES blas)
  if(OMC_SYSTEM_LIBBLAS_FOUND)
    set(OMC_RT_BLAS_LIBS "-llapack -lblas")
  else()
    set(OMC_RT_BLAS_LIBS "-lopenblas")
  endif()
  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC ${OMC_RT_BLAS_LIBS} -lm -lpthread -rdynamic")
  set(RT_LDFLAGS_GENERATED_CODE_MMC " -lOpenModelicaRuntimeMMC -lomcgc ${OMC_RT_BLAS_LIBS} -lm -lpthread -rdynamic")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lzlib ${OMC_RT_BLAS_LIBS} -lm -ldl -lpthread -lgfortran -lstdc++ -rdynamic ")
  set(RT_LDFLAGS_GENERATED_CODE_SIM_RUST " -lSimulationRuntimeRust -lOpenModelicaRuntimeC -lzlib ${OMC_RT_BLAS_LIBS} -lm -ldl -lpthread -lgfortran -lstdc++ -rdynamic ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " ${OMC_RT_BLAS_LIBS} -lm -lpthread -rdynamic ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-Wl,-Bstatic -lSimulationRuntimeFMI -Wl,-Bdynamic ${OMC_RT_BLAS_LIBS} -lm -ldl -lpthread -lgfortran -lstdc++ -rdynamic ")
else()
  message(FATAL_ERROR "Unknown system for OpenModelica simulation code generation and compilation. OpenModelica does not know how to compile and simulate simulation code on this configuration.")
endif()

# libSimulationRuntimeC writes result files through libomc_result.
if(NOT MSVC)
  string(APPEND RT_LDFLAGS_GENERATED_CODE_SIM " -lomc_result ")
endif()

# A coverage build instruments the runtime, so anything omc links against it
# needs the gcov runtime too. Linking a *shared* instrumented runtime is fine
# on its own (libgcov is already inside it), but the static variants - the
# source FMUs above all link one - would otherwise fail with undefined
# references to __gcov_*/llvm_gcda_*. Harmless where it is not needed.
if(OM_ENABLE_COVERAGE)
  foreach(_flags RT_LDFLAGS_GENERATED_CODE
                 RT_LDFLAGS_GENERATED_CODE_MMC
                 RT_LDFLAGS_GENERATED_CODE_SIM
                 RT_LDFLAGS_GENERATED_CODE_SIM_RUST
                 RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU
                 RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC)
    string(APPEND ${_flags} " --coverage ")
  endforeach()
endif()
