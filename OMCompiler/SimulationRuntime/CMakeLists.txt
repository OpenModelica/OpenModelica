
omc_add_subdirectory(c)

# The GUI-only build against a prebuilt cdylib (RUST_OMC_PREBUILT_CDYLIB) links
# just the core C runtime (c/, via OMPlot -> OpenModelicaRuntimeC); skip the rest
# of the simulation runtime so it is not rebuilt in that stage.
if(NOT RUST_OMC_PREBUILT_CDYLIB)
  if(OM_OMC_ENABLE_CPP_RUNTIME)
    omc_add_subdirectory(cpp)
  endif()
  omc_add_subdirectory(fmi)

  omc_add_subdirectory(ModelicaExternalC)

  # omc_add_subdirectory(opc)

  # ParModelica
  # Not built with MSVC yet.
  if(NOT MSVC AND OM_OMC_ENABLE_PARMODELICA)
    omc_add_subdirectory(ParModelica)
  endif()
endif()
