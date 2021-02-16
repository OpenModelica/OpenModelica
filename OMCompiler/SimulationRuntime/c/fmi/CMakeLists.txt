
INCLUDE_DIRECTORIES("${OMCTRUNCHOME}/OMCompiler/3rdParty/FMIL/install_msvc/include")

# Quellen und Header
SET(fmi_sources  FMI2Common.c  FMI2ModelExchange.c)

SET(fmi_headers  FMI2Common.h)

# Library OpenModelicaFMIRuntimeC
ADD_LIBRARY(OpenModelicaFMIRuntimeC ${fmi_sources} ${fmi_headers})

# Install
INSTALL(TARGETS OpenModelicaFMIRuntimeC
    ARCHIVE DESTINATION lib/omc)
