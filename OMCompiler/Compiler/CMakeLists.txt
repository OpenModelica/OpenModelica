
omc_add_subdirectory(runtime)


set(OMC_EXE ${PROJECT_SOURCE_DIR}/../build/bin/omc)

# list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/.cmake")
# enable_language(MODELICA)

macro(add_interface_checker_script mo_source_file)

    get_filename_component(file_name_no_ext ${mo_source_file} NAME_WLE)
    get_filename_component(source_dir ${mo_source_file} DIRECTORY)

    set(MM_PACKAGE_NAME ${file_name_no_ext})
    set(MM_INPUT_SOURCE_DIR ${source_dir})
    set(MM_OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/.cmake/mm_check_interface.in.mos ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.check_interface.mos)
endmacro(add_interface_checker_script)

macro(add_compile_script mo_source_file)
    get_filename_component(file_name_no_ext ${mo_source_file} NAME_WLE)
    get_filename_component(source_dir ${mo_source_file} DIRECTORY)

    set(MM_PACKAGE_NAME ${file_name_no_ext})
    set(MM_INPUT_SOURCE_DIR ${source_dir})
    set(MM_OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/.cmake/mm_compile.in.mos ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.compile.mos)
endmacro(add_compile_script)


add_executable(dep_scanner ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/dep_scanner.cpp)
target_compile_features(dep_scanner PRIVATE cxx_std_11)






macro(add_interface_check_step mo_source_file)
    add_interface_checker_script(${mo_source_file})

    get_filename_component(file_name_no_ext ${mo_source_file} NAME_WLE)
    get_filename_component(source_dir ${mo_source_file} DIRECTORY)

    add_custom_command(
        DEPENDS ${mo_source_file}
                ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.check_interface.mos

        COMMAND ${OMC_EXE} -g=MetaModelica -n=1 --locale=en ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.check_interface.mos

        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo.tmp
        BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo
        COMMENT "Checking interface for ${mo_source_file}"
    )

    set(OMC_MM_SOURCE_FILES ${OMC_MM_SOURCE_FILES} ${mo_source_file})

    set(OMC_MM_INTERFACE_FILES ${OMC_MM_INTERFACE_FILES} ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo)
    set(OMC_MM_STAMP_FILES ${OMC_MM_STAMP_FILES} ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo.tmp)


    add_custom_command(
        DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo
        COMMAND ${CMAKE_COMMAND} -E cat ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.rev_depends
        COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.rev_deps.stamp
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.rev_deps.stamp
        COMMENT "Touched dependents of ${mo_source_file}"
    )
    set(OMC_REV_DEP_STAMP_FILES ${OMC_REV_DEP_STAMP_FILES} ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.rev_deps.stamp)

endmacro(add_interface_check_step)




macro(add_compile_step mo_source_file)

    add_compile_script(${mo_source_file})

    get_filename_component(file_name_no_ext ${mo_source_file} NAME_WLE)
    get_filename_component(source_dir ${mo_source_file} DIRECTORY)

    add_custom_command(
        DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo.tmp
                ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.compile.mos

        COMMAND ${OMC_EXE} -g=MetaModelica -n=1 --locale=en ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.compile.mos

        OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/c_files/${file_name_no_ext}.c
                ${CMAKE_CURRENT_BINARY_DIR}/c_files/${file_name_no_ext}_records.c
                ${CMAKE_CURRENT_BINARY_DIR}/c_files/${file_name_no_ext}.h
                ${CMAKE_CURRENT_BINARY_DIR}/c_files/${file_name_no_ext}_includes.h

        BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/c_files/${file_name_no_ext}.deps

        COMMENT "Translating ${mo_source_file}"
    )

    set(OMC_C_SOURCE_FILES ${OMC_C_SOURCE_FILES} ${CMAKE_CURRENT_BINARY_DIR}/c_files/${file_name_no_ext}.c
                                                   ${CMAKE_CURRENT_BINARY_DIR}/c_files/${file_name_no_ext}_records.c)
endmacro(add_compile_step)






include(${CMAKE_CURRENT_SOURCE_DIR}/.cmake/template_compilation.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/.cmake/meta_modelica_source_list.cmake)

foreach(OMC_MM_SOURCE ${OMC_MM_ALWAYS_SOURCES})
    add_interface_check_step(${OMC_MM_SOURCE})
    add_compile_step(${OMC_MM_SOURCE})
endforeach()

foreach(OMC_MM_SOURCE ${OMC_MM_BACKEND_SOURCES})
    add_interface_check_step(${OMC_MM_SOURCE})
    add_compile_step(${OMC_MM_SOURCE})
endforeach()


add_custom_target(INTERFACE_CHECK
                  DEPENDS ${OMC_MM_STAMP_FILES}
                  COMMENT "Checked interfaces of modified MetaModelica sources.")

add_custom_command(
                DEPENDS ${OMC_MM_INTERFACE_FILES}
                COMMAND $<TARGET_FILE:dep_scanner> ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/package_list.txt ${CMAKE_CURRENT_BINARY_DIR}
                COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/dep_scan.stamp
                OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/dep_scan.stamp
                COMMENT "Scanning reverse dependencies for MetaModelica sources.")
add_custom_target(DEPENDENCY_SCAN
                  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/dep_scan.stamp
                  COMMENT "Scanned reverse dependencies for MetaModelica sources.")


add_custom_target(DEPENDENCY_UPDATE
                  DEPENDS ${OMC_REV_DEP_STAMP_FILES}
                  COMMENT "Updated dependencies for MetaModelica sources.")


add_dependencies(DEPENDENCY_SCAN INTERFACE_CHECK)
add_dependencies(DEPENDENCY_UPDATE DEPENDENCY_SCAN)

add_library(OpenModelicaCompiler STATIC ${OMC_C_SOURCE_FILES} .cmake/omc_entry_point.c)
target_compile_definitions(OpenModelicaCompiler PRIVATE ADD_METARECORD_DEFINITIONS=)

add_dependencies(OpenModelicaCompiler DEPENDENCY_UPDATE)

include_regular_expression("^$")
# There is a lonely omc_file.h in Util/. It belongs in runtime/. Remove this when it is moved.
target_include_directories(OpenModelicaCompiler PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/Util)

# include_regular_expression("^.*$" "^$")


target_link_libraries(OpenModelicaCompiler PUBLIC omc::parser)
target_link_libraries(OpenModelicaCompiler PUBLIC omc::compiler::runtime)
target_link_libraries(OpenModelicaCompiler PUBLIC omc::compiler::backendruntime)
target_link_libraries(OpenModelicaCompiler PUBLIC omc::compiler::graphstream)
target_link_libraries(OpenModelicaCompiler PUBLIC OpenModelicaRuntimeC)
target_link_libraries(OpenModelicaCompiler PUBLIC omc::3rd::modelica_external_c)
target_link_libraries(OpenModelicaCompiler PUBLIC omc::3rd::modelica_io)




# OMC Executable.
add_executable(omc .cmake/omc_main.c)
target_link_libraries(omc OpenModelicaCompiler)
