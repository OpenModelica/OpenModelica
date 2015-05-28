# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

# Subdirectorys
#ADD_SUBDIRECTORY(libf2c)
ADD_SUBDIRECTORY(results)
ADD_SUBDIRECTORY(solver)

# Include Directory of expat
INCLUDE_DIRECTORIES("${OMCTRUNCHOME}/OMCompiler/3rdParty/FMIL/ThirdParty/Expat/expat-2.0.1/lib" "${OMCTRUNCHOME}/OMCompiler/Compiler/runtime/")

# Quellen und Header
SET(simulation_sources
      ../linearization/linearize.cpp
      modelinfo.c simulation_info_json.c simulation_input_xml.cpp socket.cpp
      options.c simulation_info_xml.c simulation_runtime.cpp)

SET(simulation_headers
      modelinfo.h simulation_info_json.h simulation_input_xml.h socket.h options.h simulation_info_xml.h simulation_runtime.h
      ../linearization/linearize.h ../simulation_data.h ../omc_inline.h ../util/omc_msvc.h ../openmodelica.h ../openmodelica_func.h)

# Library util
ADD_DEFINITIONS(/DNO_INTERACTIVE_DEPENDENCY)
ADD_LIBRARY(simulation ${simulation_sources} ${simulation_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS simulation
		ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${simulation_headers} DESTINATION include)
