set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/ParModelica/auto)

find_package(OpenCL REQUIRED)

set(PARMODEXP_SOURCES omc_ocl_memory_ops.cpp
                    omc_ocl_interface.cpp
                    omc_ocl_builtin_kernels.cpp
                    omc_ocl_util.cpp)


add_library(ParModelicaExpl STATIC)
TARGET_SOURCES(ParModelicaExpl PRIVATE ${PARMODEXP_SOURCES})

target_link_libraries(ParModelicaExpl PUBLIC omc::simrt::runtime)
target_link_libraries(ParModelicaExpl PUBLIC OpenCL::OpenCL)


install(TARGETS ParModelicaExpl)
install(FILES ParModelicaBuiltin.mo
            DESTINATION lib/omc)

install(FILES
            omc_ocl_interface.h
            omc_ocl_common_header.h
            omc_ocl_memory_ops.h
            OCLRuntimeUtil.cl
        TYPE INCLUDE)
