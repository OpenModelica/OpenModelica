
INCLUDE_DIRECTORIES("${OMCTRUNCHOME}/OMCompiler/3rdParty/FMIL/install_msvc/include")

# Quellen und Header
SET(fmi_sources  FMI1CoSimulation.c  FMI1Common.c  FMI1ModelExchange.c  FMI2Common.c  FMI2ModelExchange.c  FMICommon.c)

SET(fmi_headers  FMI1Common.h  FMI2Common.h  FMICommon.h)

# Library OpenModelicaFMIRuntimeC
ADD_LIBRARY(OpenModelicaFMIRuntimeC ${fmi_sources} ${fmi_headers})

# Install
INSTALL(TARGETS OpenModelicaFMIRuntimeC
    ARCHIVE DESTINATION lib/omc)

