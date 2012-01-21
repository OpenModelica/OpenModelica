# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC 

# Quellen und Header
SET(math_support_sources  bigden.c biglag.c delay.c dgesv_aux.c dogleg.c dpmpar.c
				enorm.c fdjac1.c hybrd.c hybrd1.c hybrj.c initialization.c lsame.c
				model_help.c nelmead.c newuoa.c newuob.c qform.c qrfac.c r1mpyq.c
                r1updt.c trsapp.c update.c)

SET(math_support_headers  blaswrap.h delay.h initialization.h matrix.h model_help.h) 
						 
# Library util
ADD_LIBRARY(math-support ${math_support_sources} ${math_support_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS math-support
		ARCHIVE DESTINATION lib)
		
INSTALL(FILES ${math_support_headers} DESTINATION include)

