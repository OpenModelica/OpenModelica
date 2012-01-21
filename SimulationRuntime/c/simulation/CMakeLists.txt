# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC 

# Subdirectorys
ADD_SUBDIRECTORY(libf2c)
ADD_SUBDIRECTORY(results)
ADD_SUBDIRECTORY(solver)

# Quellen und Header
SET(simulation_sources  options.cpp simulation_input_xml.cpp simulation_runtime.cpp
					    ../linearization/linearize.cpp)

SET(simulation_headers options.h simulation_input_xml.h simulation_runtime.h
					../linearization/linearize.h ../simulation_data.h)				 
						 
# Library util
ADD_DEFINITIONS(/DNO_INTERACTIVE_DEPENDENCY)
ADD_LIBRARY(simulation ${simulation_sources} ${simulation_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS simulation
		ARCHIVE DESTINATION lib)
		
INSTALL(FILES ${simulation_headers} DESTINATION include)