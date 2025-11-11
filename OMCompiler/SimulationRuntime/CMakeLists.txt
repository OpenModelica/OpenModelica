
omc_add_subdirectory(c)
omc_add_subdirectory(fmi)

if(OM_OMC_ENABLE_CPP_RUNTIME)
  omc_add_subdirectory(cpp)
endif()

# ModelicaExternalC
# Disable ModelicaExternalC for MSVC since right now we are building static
# and shared versions of the library with the *same name*. This works on linux
# and MinGW because lib.a and lib.so. MSVC, however, wants to build an import
# lib (.lib) for DLLs. This conflicts with the static library (also .lib).
if(NOT MSVC)
  omc_add_subdirectory(ModelicaExternalC)
endif()

# omc_add_subdirectory(opc)

# ParModelica
# Disable for MSVC. There are some issues with Boost which need to be fixed.
if(NOT MSVC)
  omc_add_subdirectory(ParModelica)
endif()

#ADD_SUBDIRECTORY(cpp)
#ADD_SUBDIRECTORY(interactive)
