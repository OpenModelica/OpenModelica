# The compiler translated to C for x86_64-windows-msvc, for a cross build of the
# C omc to build with OM_OMC_PREBUILT_C_SOURCES, as it cannot run omc itself.
#
#   cmake --build <build_dir> --target generate-msvc-c-sources
#
# writes them to <build_dir>/OMCompiler/Compiler/msvc-c-sources.
#
# The C of this build cannot be used for that: MetaModelica inlines the
# constants of Autoconf into every package using them, so each carries the
# configuration of the build host. Everything is translated again, against an
# Autoconf configured for MSVC and the interfaces of this build.

set(OMC_MSVC_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/msvc-sources)
set(OMC_MSVC_C_DIR ${CMAKE_CURRENT_BINARY_DIR}/msvc-c-sources)

# What runtime/CMakeLists.txt configures Autoconf.mo with for MSVC.
function(omc_configure_msvc_autoconf output)
  set(MSVC TRUE)
  set(MINGW FALSE)
  include(${CMAKE_CURRENT_SOURCE_DIR}/runtime/rt_ldflags_generated_code.cmake)
  set(CONFIG_OS "Windows_NT")
  set(OMC_TARGET_ARCH_IS_64 "true")
  set(OMC_MAKE_EXE "make")
  set(SHREXT ".dll")
  set(BSTATIC "false")
  set(OMC_HDF5_LDFLAGS "")
  set(PARMODELICAAUTO_LDFLAGS " -lParModelicaAuto -ltbb12 ")
  set(WITH_HWLOC 0)
  set(host_short "x86_64-windows-msvc")
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Util/Autoconf.mo.in ${output})
endfunction()

omc_configure_msvc_autoconf(${OMC_MSVC_BINARY_DIR}/Util/Autoconf.mo)

set(MM_PACKAGE_NAME Autoconf)
set(MM_INPUT_SOURCE_DIR ${OMC_MSVC_BINARY_DIR}/Util)
set(MM_OUTPUT_DIR ${OMC_MSVC_BINARY_DIR})
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/.cmake/mm_check_interface.in.mos
               ${OMC_MSVC_BINARY_DIR}/Autoconf.check_interface.mos)

add_custom_command(
    DEPENDS ${OMC_MM_STAMP_FILES}
            ${OMC_MSVC_BINARY_DIR}/Util/Autoconf.mo
            ${OMC_MSVC_BINARY_DIR}/Autoconf.check_interface.mos
            ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/copy_mm_interfaces.cmake

    COMMAND ${CMAKE_COMMAND} -DFROM=${CMAKE_CURRENT_BINARY_DIR} -DTO=${OMC_MSVC_BINARY_DIR}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/copy_mm_interfaces.cmake
    COMMAND ${OMC_EXE} -g=MetaModelica -n=1 ${OMC_MSVC_BINARY_DIR}/Autoconf.check_interface.mos
    COMMAND ${CMAKE_COMMAND} -E touch ${OMC_MSVC_BINARY_DIR}/interfaces.stamp

    OUTPUT ${OMC_MSVC_BINARY_DIR}/interfaces.stamp
    COMMENT "Collecting the interfaces for the MSVC sources"
)

foreach(OMC_MM_SOURCE ${OMC_MM_ALWAYS_SOURCES} ${OMC_MM_BACKEND_SOURCES})
    get_filename_component(file_name_no_ext ${OMC_MM_SOURCE} NAME_WLE)
    get_filename_component(source_dir ${OMC_MM_SOURCE} DIRECTORY)
    if(file_name_no_ext STREQUAL "Autoconf")
        set(source_dir ${OMC_MSVC_BINARY_DIR}/Util)
    endif()

    set(MM_PACKAGE_NAME ${file_name_no_ext})
    set(MM_INPUT_SOURCE_DIR ${source_dir})
    set(MM_OUTPUT_DIR ${OMC_MSVC_BINARY_DIR})
    set(MM_C_OUTPUT_DIR ${OMC_MSVC_C_DIR})
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/.cmake/mm_compile.in.mos
                   ${OMC_MSVC_BINARY_DIR}/${file_name_no_ext}.compile.mos)

    add_custom_command(
        DEPENDS ${OMC_MSVC_BINARY_DIR}/interfaces.stamp
                ${OMC_MSVC_BINARY_DIR}/${file_name_no_ext}.compile.mos
                ${source_dir}/${file_name_no_ext}.mo

        COMMAND ${OMC_EXE} -g=MetaModelica -n=1 ${CHECK_DEF_USE}
                ${OMC_MSVC_BINARY_DIR}/${file_name_no_ext}.compile.mos

        OUTPUT  ${OMC_MSVC_C_DIR}/${file_name_no_ext}.c
                ${OMC_MSVC_C_DIR}/${file_name_no_ext}_records.c
                ${OMC_MSVC_C_DIR}/${file_name_no_ext}.h
                ${OMC_MSVC_C_DIR}/${file_name_no_ext}_includes.h

        BYPRODUCTS ${OMC_MSVC_C_DIR}/${file_name_no_ext}.deps

        COMMENT "Translating ${file_name_no_ext}.mo for MSVC"
    )

    list(APPEND OMC_MSVC_C_FILES ${OMC_MSVC_C_DIR}/${file_name_no_ext}.c)
endforeach()

add_custom_target(generate-msvc-c-sources
                  DEPENDS ${OMC_MSVC_C_FILES}
                  COMMENT "Generated the MSVC sources in ${OMC_MSVC_C_DIR}.")
add_dependencies(generate-msvc-c-sources DEPENDENCY_UPDATE)
