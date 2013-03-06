# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

# Subdirectorys
ADD_SUBDIRECTORY(libf2c)
ADD_SUBDIRECTORY(results)
ADD_SUBDIRECTORY(solver)

# Include Directory of expat
INCLUDE_DIRECTORIES("${OMCTRUNCHOME}/3rdParty/FMIL/ThirdParty/Expat/expat-2.0.1/lib")

# Quellen und Header
SET(simulation_sources  options.c simulation_input_xml.cpp simulation_runtime.cpp
					    ../linearization/linearize.cpp
						modelinfo.c simulation_info_xml.c)

SET(simulation_headers options.h simulation_input_xml.h simulation_runtime.h modelinfo.h simulation_info_xml.h
					../linearization/linearize.h ../simulation_data.h ../omc_inline.h ../util/omc_msvc.h ../openmodelica.h ../openmodelica_func.h)

# Library util
ADD_DEFINITIONS(/DNO_INTERACTIVE_DEPENDENCY)
ADD_LIBRARY(simulation ${simulation_sources} ${simulation_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS simulation
		ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${simulation_headers} DESTINATION include)
