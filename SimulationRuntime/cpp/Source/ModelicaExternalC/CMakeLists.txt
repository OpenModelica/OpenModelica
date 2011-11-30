cmake_minimum_required (VERSION 2.6)
project(ModelicaExternalC)
add_library(ModelicaExternalC  ModelicaTablesImpl.c tables.cpp  )

install (TARGETS ModelicaExternalC DESTINATION  lib/omc/cpp)
		
