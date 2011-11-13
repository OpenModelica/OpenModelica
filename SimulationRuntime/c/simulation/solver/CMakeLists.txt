# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC 

# Quellen und Header
SET(solver_sources  daux.c ddasrt.c 
                    ddassl.c 
					dlamch.c 
					dlinpk.c 
					solver_main.c )
#					dopri45.c  )

SET(solver_headers  simulation_inline_solver.h solver_main.h ) 
                    #dopri45.h)				 
						 
# Library util
ADD_LIBRARY(solver ${solver_sources} ${solver_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS solver
		ARCHIVE DESTINATION lib)
		
INSTALL(FILES ${solver_headers} DESTINATION include)

