# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

# Quellen und Header
SET(initialization_sources  initialization.c
                            initialization_data.c
							method_ipopt.c
							method_kinsol.c
							method_newuoa.c
							method_simplex.c
							method_nelderMeadEx.c)

SET(initialization_headers  initialization.h
                            initialization_data.h
							method_ipopt.h
							method_kinsol.h
							method_newuoa.h
							method_simplex.h
							method_nelderMeadEx.h)

# Library util
ADD_LIBRARY(initialization ${initialization_sources} ${initialization_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS initialization
		ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${initialization_headers} DESTINATION include)

