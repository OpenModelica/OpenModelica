# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC 

ADD_SUBDIRECTORY(initialization)

# Quellen und Header
SET(solver_sources  daux.c
                    ddasrt.c
					ddassl.c
					dassl.c
					delay.c
					dlamch.c
					dlinpk.c
					events.c
					model_help.c
					solver_main.c)

SET(solver_headers  dassl.h
                    delay.h 
					events.h 
					model_help.h 
					solver_main.h)				 
						 
# Library util
ADD_LIBRARY(solver ${solver_sources} ${solver_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS solver
		ARCHIVE DESTINATION lib/omc)
		
#INSTALL(FILES ${solver_headers} DESTINATION include)

