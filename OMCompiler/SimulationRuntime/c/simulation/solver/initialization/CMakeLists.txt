# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

# Quellen und Header
SET(initialization_sources  initialization.c)

SET(initialization_headers  initialization.h)

INCLUDE_DIRECTORIES("${OMCTRUNCHOME}/OMCompiler/Compiler/runtime/")

# Library util
ADD_LIBRARY(initialization ${initialization_sources} ${initialization_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS initialization
		ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${initialization_headers} DESTINATION include)

