
omc_add_subdirectory(c)

# The GUI-only build against a prebuilt cdylib (RUST_OMC_PREBUILT_CDYLIB) links
# just the core C runtime (c/, via OMPlot -> OpenModelicaRuntimeC); skip the rest
# of the simulation runtime so it is not rebuilt in that stage.
if(NOT RUST_OMC_PREBUILT_CDYLIB)
  if(OM_OMC_ENABLE_CPP_RUNTIME)
    omc_add_subdirectory(cpp)
  endif()
  omc_add_subdirectory(fmi)

  # ModelicaExternalC. The static and shared libraries in this subdirectory
  # give MSVC's import lib (.lib) for the DLL the same name as the static
  # library (also .lib) - unlike Unix (.a vs .so) or MinGW (.a vs .dll.a),
  # which never collide - so on MSVC the static ones get a _static suffix
  # (see the OUTPUT_NAME overrides in ModelicaExternalC/CMakeLists.txt).
  omc_add_subdirectory(ModelicaExternalC)

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
    # The C++ OMSI runtime: same OMCpp* libraries and Boost as cpp/ above.
    if(OM_OMC_ENABLE_CPP_RUNTIME)
      omc_add_subdirectory(OMSICpp)
    endif()
  endif()

  # omc_add_subdirectory(opc)

  # ParModelica
  # Disable for MSVC. There are some issues with Boost which need to be fixed.
  if(NOT MSVC AND OM_OMC_ENABLE_PARMODELICA)
    omc_add_subdirectory(ParModelica)
  endif()
endif()
