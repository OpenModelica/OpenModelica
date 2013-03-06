cmake_minimum_required (VERSION 2.6)

project(${ModelicaExternalName})
add_library(${ModelicaExternalName}    ModelicaTablesImpl.c tables.cpp  )

install (TARGETS ${ModelicaExternalName} DESTINATION  lib/omc/${LIBINSTALLEXT})

#lib/omc/cpp
