# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC 

# Quellen und Header
SET(math_support_sources  bigden.c enorm.c hybrd1.c nelmead.c qform.c r1updt.c
                  biglag.c dogleg.c fdjac1.c hybrj.c newuoa.c qrfac.c trsapp.c
				  dpmpar.c hybrd.c lsame.c newuob.c r1mpyq.c update.c
				  simulation_events.c simulation_delay.c
				  simulation_init.c dgesv_aux.c ringbuffer.c list.c)

SET(math_support_headers  blaswrap.h matrix.h ringbuffer.h simulation_delay.h
                  simulation_events.h simulation_init.h list.h) 
						 
# Library util
ADD_LIBRARY(math-support ${math_support_sources} ${math_support_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS math-support
		ARCHIVE DESTINATION lib)
		
INSTALL(FILES ${math_support_headers} DESTINATION include)

