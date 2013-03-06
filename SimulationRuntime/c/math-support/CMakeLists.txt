# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

# Quellen und Header
SET(math_support_sources  bigden.c biglag.c dogleg.c dpmpar.c
                          daux.c ddassl.c ddasrt.c dlamch.c dlinpk.c
                          enorm.c fdjac1.c hybrd.c hybrd1.c hybrj.c lsame.c
                          nelmead.c newuoa.c newuob.c  pivot.c qform.c  qrfac.c r1mpyq.c
                          r1updt.c trsapp.c update.c)

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
