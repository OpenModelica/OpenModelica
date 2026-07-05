
omc_add_subdirectory(c)

# The GUI-only build against a prebuilt cdylib (RUST_OMC_PREBUILT_CDYLIB) links
# just the core C runtime (c/, via OMPlot -> OpenModelicaRuntimeC); skip the rest
# of the simulation runtime so it is not rebuilt in that stage.
if(NOT RUST_OMC_PREBUILT_CDYLIB)
  if(OM_OMC_ENABLE_CPP_RUNTIME)
    omc_add_subdirectory(cpp)
  endif()
  omc_add_subdirectory(fmi)

  # ModelicaExternalC
  # Disable ModelicaExternalC for MSVC since right now we are building static
  # and shared versions of the library with the *same name*. This works on linux
  # and MinGW because lib.a and lib.so. MSVC, however, wants to build an import
  # lib (.lib) for DLLs. This conflicts with the static library (also .lib).
  if(NOT MSVC)
    omc_add_subdirectory(ModelicaExternalC)
  endif()

  # OMSI
  #
  # Makefiles currently prefer the static version of libOMSI*
  if(NOT DEFINED PLATFORM AND NOT DEFINED CACHE{PLATFORM})
    set(PLATFORM "static")
  endif()
  # The OMSI runtimes assume a MinGW/MSYS2 toolchain on Windows (OMSICpp hard-
  # requires $ENV{MSYSTEM_PREFIX} and bundled-under-OMHOME Boost), so they are
  # not yet buildable in the MSVC cross build — disable for MSVC, like
  # ModelicaExternalC / ParModelica above.
  if(NOT MSVC)
    omc_add_subdirectory(OMSI)
    omc_add_subdirectory(OMSIC)
    omc_add_subdirectory(OMSICpp)
  endif()

  # omc_add_subdirectory(opc)

  # ParModelica
  # Disable for MSVC. There are some issues with Boost which need to be fixed.
  if(NOT MSVC)
    omc_add_subdirectory(ParModelica)
  endif()
endif()
