
# This macro takes a template file and list of dependencies as inputs.
# You can use it as:
#           omc_add_template_target(SOURCE CodegenC.tpl
#                                   DEPENDS CodegenCFunctions.tpl SimCodeTV.mo CodegenUtil.tpl)

# dependencies can be, for example, typeview files used by the template.
# They are needed so that the tpl file is compiled again if any of the
# dependencies is modified.
macro(omc_add_template_target)

    # parse the named macro arguments. "<flags>" "<singlevalueargs>" "<multivalueargs>"
    cmake_parse_arguments(TPL_MACRO_ARGS "" "SOURCE" "DEPENDS" ${ARGN} )

    set(template_file ${TPL_MACRO_ARGS_SOURCE})
    set(depends_on ${TPL_MACRO_ARGS_DEPENDS})
    # message(STATUS "${template_file} : ${depends_on}")

    get_filename_component(file_name_no_ext ${template_file} NAME_WE)
    set(output_mo_file ${file_name_no_ext}.mo)
    # omc generates the mo file in the current dir. So we might as well put the log
    # there for now.
    # set(output_log_file ${output_dir}/${file_name_no_ext}.log)
    set(output_log_file ${file_name_no_ext}.log)

    add_custom_command(
        # We need to work in the directory where the tpl files are located because
        # omc tpl has no concept of library directory. It will look for imported things
        # in the current directory only.
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}

        DEPENDS ${template_file} ${depends_on}
        COMMAND ${OMC_EXE} -d=failtrace
        ARGS ${template_file} > ${output_log_file}
                || (cat ${output_log_file} && false)

        OUTPUT ${output_mo_file}
        COMMENT "Generating ${output_mo_file} from ${template_file}"
    )


    # mark the .mo file as generated
    set_source_files_properties(${output_mo_file} GENERATED)

    set(TPL_${file_name_no_ext}_OUTPUT ${output_mo_file})

    # Add the output to the list of all mo files generated from templates.
    set(TPL_OUTPUT_MO_FILES ${TPL_OUTPUT_MO_FILES} ${output_mo_file})

    message(STATUS "added Susan template target ${template_file} dependent on ${depends_on}")

endmacro(omc_add_template_target)








omc_add_template_target(SOURCE CodegenC.tpl
                        DEPENDS CodegenCFunctions.tpl SimCodeTV.mo CodegenUtil.tpl)
omc_add_template_target(SOURCE CodegenUtilSimulation.tpl
                        DEPENDS SimCodeTV.mo)
omc_add_template_target(SOURCE CodegenEmbeddedC.tpl
                        DEPENDS SimCodeTV.mo CodegenUtil.tpl)
omc_add_template_target(SOURCE CodegenFMUCommon.tpl
                        DEPENDS SimCodeTV.mo SimCodeBackendTV.mo CodegenC.tpl CodegenCFunctions.tpl CodegenUtil.tpl)
omc_add_template_target(SOURCE CodegenFMU.tpl
                        DEPENDS CodegenFMU2.tpl CodegenFMUCommon.tpl CodegenFMUCommon.mo SimCodeTV.mo SimCodeBackendTV.mo CodegenC.tpl CodegenCFunctions.tpl CodegenUtil.tpl)
omc_add_template_target(SOURCE CodegenFMU1.tpl
                        DEPENDS CodegenFMUCommon.tpl CodegenFMUCommon.mo SimCodeTV.mo SimCodeBackendTV.mo CodegenC.tpl CodegenUtil.tpl)
omc_add_template_target(SOURCE CodegenFMU2.tpl
                        DEPENDS CodegenFMUCommon.tpl CodegenFMUCommon.mo SimCodeTV.mo SimCodeBackendTV.mo CodegenC.tpl CodegenUtil.tpl)
omc_add_template_target(SOURCE CodegenCSharp.tpl
                        DEPENDS SimCodeTV.mo)
omc_add_template_target(SOURCE CodegenCppCommon.tpl
                        DEPENDS SimCodeTV.mo)
omc_add_template_target(SOURCE CodegenCpp.tpl
                        DEPENDS SimCodeTV.mo CodegenUtil.tpl CodegenCppInit.tpl CodegenCppCommon.tpl)
omc_add_template_target(SOURCE CodegenCppHpcom.tpl
                        DEPENDS SimCodeTV.mo SimCodeBackendTV.mo CodegenCpp.tpl CodegenUtil.tpl)
omc_add_template_target(SOURCE CodegenFMUCpp.tpl
                        DEPENDS SimCodeTV.mo SimCodeBackendTV.mo CodegenC.tpl CodegenUtil.tpl CodegenCpp.tpl  CodegenCppCommon.tpl CodegenFMU.tpl)
omc_add_template_target(SOURCE CodegenOMSI_common.tpl
                        DEPENDS SimCodeTV.mo SimCodeBackendTV.mo CodegenUtil.tpl CodegenUtilSimulation.tpl CodegenCFunctions.tpl)
omc_add_template_target(SOURCE CodegenOMSIC.tpl
                        DEPENDS SimCodeTV.mo SimCodeBackendTV.mo CodegenOMSI_common.tpl CodegenUtil.tpl CodegenUtilSimulation.tpl CodegenFMU.tpl)
omc_add_template_target(SOURCE CodegenOMSICpp.tpl
                        DEPENDS SimCodeTV.mo SimCodeBackendTV.mo CodegenC.tpl CodegenUtil.tpl CodegenCpp.tpl  CodegenCppCommon.tpl CodegenFMU.tpl)
omc_add_template_target(SOURCE CodegenOMSIC_Equations.tpl
                        DEPENDS SimCodeTV.mo SimCodeBackendTV.mo CodegenC.tpl CodegenCFunctions.tpl CodegenUtil.tpl CodegenUtilSimulation.tpl)
omc_add_template_target(SOURCE CodegenFMUCppHpcom.tpl
                        DEPENDS CodegenFMUCpp.tpl SimCodeTV.mo SimCodeBackendTV.mo CodegenCppHpcom.tpl CodegenUtil.tpl CodegenCppCommon.tpl)
omc_add_template_target(SOURCE CodegenCppInit.tpl
                        DEPENDS SimCodeTV.mo SimCodeBackendTV.mo CodegenUtil.tpl CodegenFMUCommon.tpl)
omc_add_template_target(SOURCE CodegenMidToC.tpl
                        DEPENDS SimCodeTV.mo MidCodeTV.mo)
omc_add_template_target(SOURCE GraphvizDump.tpl
                        DEPENDS SimCodeTV.mo SimCodeBackendTV.mo)
omc_add_template_target(SOURCE GraphMLDumpTpl.tpl
                        DEPENDS GraphMLDumpTplTV.mo)
omc_add_template_target(SOURCE NFInstDumpTpl.tpl
                        DEPENDS NFInstDumpTV.mo)
omc_add_template_target(SOURCE SimCodeDump.tpl
                        DEPENDS SimCodeTV.mo CodegenUtil.tpl SCodeDumpTpl.tpl)
omc_add_template_target(SOURCE CodegenAdevs.tpl
                        DEPENDS SimCodeTV.mo)
omc_add_template_target(SOURCE CodegenSparseFMI.tpl
                        DEPENDS SimCodeTV.mo)
omc_add_template_target(SOURCE CodegenXML.tpl
                        DEPENDS SimCodeTV.mo)
omc_add_template_target(SOURCE CodegenJava.tpl
                        DEPENDS SimCodeTV.mo)
omc_add_template_target(SOURCE CodegenJS.tpl
                        DEPENDS SimCodeTV.mo)
omc_add_template_target(SOURCE TaskSystemDump.tpl
                        DEPENDS SimCodeTV.mo CodegenUtil.tpl SCodeDumpTpl.tpl)
omc_add_template_target(SOURCE VisualXMLTpl.tpl
                        DEPENDS VisualXMLTplTV.mo)


# omc_add_template_target(SOURCE CodegenModelica.tpl
#                         DEPENDS GraphvizDump.tpl)

