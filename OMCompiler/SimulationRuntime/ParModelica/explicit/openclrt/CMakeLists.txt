set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/c/ParModelica/explicit/openclrt)

# Diagnostics from the OpenCL runtime
omc_option(OM_OMC_PARMODELICA_OCL_VERBOSE
           "Print verbose OpenCL diagnostics from the ParModelica explicit runtime." OFF)

set(PARMODEXP_SOURCES omc_ocl_memory_ops.cpp
                    omc_ocl_interface.cpp
                    omc_ocl_builtin_kernels.cpp
                    omc_ocl_util.cpp)


add_library(ParModelicaExpl STATIC)
TARGET_SOURCES(ParModelicaExpl PRIVATE ${PARMODEXP_SOURCES})

target_link_libraries(ParModelicaExpl PUBLIC omc::simrt::runtime)
target_link_libraries(ParModelicaExpl PUBLIC OpenCL::OpenCL)

if(OM_OMC_PARMODELICA_OCL_VERBOSE)
  target_compile_definitions(ParModelicaExpl PRIVATE BE_OCL_VERBOSE)
endif()

install(TARGETS ParModelicaExpl)
install(FILES ParModelicaBuiltin.mo
            DESTINATION lib/omc)

install(FILES
            omc_ocl_interface.h
            omc_ocl_common_header.h
            omc_ocl_memory_ops.h
            OCLRuntimeUtil.cl
        TYPE INCLUDE)
