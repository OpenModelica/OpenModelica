# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

# Quellen und Header
SET(math_support_sources  bigden.c biglag.c dlamch.c lsame.c
                          nelmead.c newuoa.c newuob.c  pivot.c 
                          trsapp.c update.c)

SET(math_support_headers blaswrap.h)

# Library util
ADD_LIBRARY(math-support ${math_support_sources} ${math_support_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS math-support
		ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${math_support_headers} DESTINATION include)

# add tests
#ADD_SUBDIRECTORY(test)
