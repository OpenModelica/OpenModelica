
# This macro takes a template file and list of dependencies as inputs.
# You can use it as:
#           omc_add_template_target(SOURCE CodegenC.tpl
#                                   DEPENDS CodegenCFunctions.tpl SimCodeTV.mo CodegenUtil.tpl)

# dependencies can be, for example, typeview files used by the template.
# They are needed so that the tpl file is compiled again if any of the
# dependencies is modified.
## TODO: Add a proper dependency scanner for susan template files. It is not a complicated
## dependency system. A simple regex should probably do the job. We just need to integrate
## it into cmake so that they are re-scanned and updated properly(recursively) when modified.
macro(omc_add_template_target)

    # parse the named macro arguments. "<flags>" "<singlevalueargs>" "<multivalueargs>"
    cmake_parse_arguments(TPL_MACRO_ARGS "" "SOURCE" "DEPENDS" ${ARGN} )

    set(template_file ${TPL_MACRO_ARGS_SOURCE})
    set(depends_on ${TPL_MACRO_ARGS_DEPENDS})
    # message(STATUS "${template_file} : ${depends_on}")

    get_filename_component(file_name_no_ext ${template_file} NAME_WLE)
    get_filename_component(source_dir ${template_file} DIRECTORY)
    set(output_mo_file ${source_dir}/${file_name_no_ext}.mo)
    # omc generates the mo file in the current dir. So we might as well put the log
    # there for now.
    # set(output_log_file ${output_dir}/${file_name_no_ext}.log)
    set(output_log_file ${source_dir}/${file_name_no_ext}.log)

    add_custom_command(
        # We need to work in the directory where the tpl files are located because
        # omc tpl has no concept of library directory. It will look for imported things
        # in the current directory only.
        WORKING_DIRECTORY ${source_dir}

        DEPENDS ${template_file} ${depends_on}
        COMMAND ${OMC_EXE} -d=failtrace ${template_file} > ${output_log_file} || (cat ${output_log_file} && false)

        OUTPUT ${output_mo_file}
        COMMENT "Generating ${output_mo_file} from ${template_file}"
    )


    # mark the .mo file as generated
    set_source_files_properties(${output_mo_file} GENERATED)

    set(TPL_${file_name_no_ext}_OUTPUT ${output_mo_file})

    # Add the output to the list of all mo files generated from templates.
    set(TPL_OUTPUT_MO_FILES ${TPL_OUTPUT_MO_FILES} ${output_mo_file})

    message(STATUS "Added Susan template target ${template_file}")

endmacro(omc_add_template_target)









omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/AbsynDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/AbsynDumpTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/AbsynJLDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/AbsynDumpTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/AbsynToJulia.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/AbsynToJuliaTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCFunctions.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/DAEDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/DAEDumpTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/ExpressionDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/ExpressionDumpTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/DAEDumpTpl.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/GenerateAPIFunctionsTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SCodeDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/AbsynDumpTpl.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/Unparsing.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)



omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCFunctions.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtilSimulation.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenEmbeddedC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCFunctions.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMU.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMU2.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCommon.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCFunctions.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMU1.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCommon.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMU2.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCommon.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCSharp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppCommonOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppInit.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppCommon.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppInit.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppCommonOld.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppHpcom.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppHpcomOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMU.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCppOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppCommonOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMU.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenOMSI_common.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtilSimulation.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCFunctions.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenOMSIC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenOMSI_common.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtilSimulation.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMU.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenOMSICpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMU.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenOMSIC_Equations.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCFunctions.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtilSimulation.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCppHpcom.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppHpcom.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppCommon.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCppHpcomOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCppOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppHpcomOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppCommonOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppOld.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMU.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenCppInit.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenFMUCommon.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenMidToC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/MidCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/GraphvizDump.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeBackendTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/GraphMLDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/GraphMLDumpTplTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/NFInstDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/NFInstDumpTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeDump.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SCodeDumpTpl.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenAdevs.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenSparseFMI.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenXML.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenJava.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenJS.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/TaskSystemDump.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/SCodeDumpTpl.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/VisualXMLTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/VisualXMLTplTV.mo)




omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}../susan_codegen/TplCodegen.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}../susan_codegen/TplCodegenTV.mo)



# omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/../Template/CodegenModelica.tpl
#                         DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../Template/GraphvizDump.tpl)


