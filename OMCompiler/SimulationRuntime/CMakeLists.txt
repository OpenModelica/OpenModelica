
omc_add_subdirectory(c)
omc_add_subdirectory(fmi)

if(OM_OMC_ENABLE_CPP_RUNTIME)
  omc_add_subdirectory(cpp)
endif()

# ModelicaExternalC
omc_add_subdirectory(ModelicaExternalC)

# omc_add_subdirectory(opc)
# omc_add_subdirectory(ParModelica)
#ADD_SUBDIRECTORY(cpp)
#ADD_SUBDIRECTORY(interactive)

