
# Where the *.mo (and the Susan log) generated from the *.tpl are written.
# Consumers refer to this directory rather than Compiler/Template:
# meta_modelica_source_list.cmake for the compiler build, and
# LoadCompilerSources.mos via OMCOMPILERGENERATEDSOURCES for the bootstrapping tests.
# The source layout is mirrored below it (generated-mo/Template,
# generated-mo/susan_codegen, ...) so a consumer only has to swap the root.
set(OMC_GENERATED_MO_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated-mo
    CACHE INTERNAL "Build-tree root holding the .mo generated from Susan templates.")

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
    get_filename_component(file_name ${template_file} NAME)
    get_filename_component(source_dir ${template_file} DIRECTORY)
    # Mirror the template's own directory (Template, susan_codegen, ...) under
    # the generated-mo root, so the tree matches the source layout.
    get_filename_component(source_subdir ${source_dir} NAME)
    set(output_dir ${OMC_GENERATED_MO_DIR}/${source_subdir})
    set(output_mo_file ${output_dir}/${file_name_no_ext}.mo)
    set(output_log_file ${output_dir}/${file_name_no_ext}.log)

    add_custom_command(
        # We need to work in the directory where the tpl files are located because
        # omc tpl has no concept of library directory. It will look for imported things
        # in the current directory only.
        WORKING_DIRECTORY ${source_dir}

        # ${TPL_EXTRA_DEPENDS} is empty for the C build; in the Rust build
        # (rust_omc.cmake) it is the rust_susan stamp, so each *.mo is
        # regenerated after the Susan binary is (re)built.
        DEPENDS ${template_file} ${depends_on} ${TPL_EXTRA_DEPENDS}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${output_dir}
        # Susan copies the template path it is given verbatim into the generated
        # .mo (Tpl.sourceInfo("...", line, column)), and from there it ends up in
        # the C generated for the compiler. Pass it relative to the working
        # directory set above so that stays "CodegenC.tpl" instead of the absolute
        # path of whoever ran the build; the bootstrapping snapshot produced by
        # .cmake/bootstrap_sources.cmake has to be the same no matter where it was
        # generated.
        COMMAND ${OMC_EXE} -d=failtrace --tplOutputDir=${output_dir} ${file_name} > ${output_log_file} || (cat ${output_log_file} && false)

        OUTPUT ${output_mo_file}
        COMMENT "Generating ${output_mo_file} from ${template_file}"
    )


    # mark the .mo file as generated
    set_source_files_properties(${output_mo_file} GENERATED)

    set(TPL_${file_name_no_ext}_OUTPUT ${output_mo_file})

    # Add the output to the list of all mo files generated from templates.
    set(TPL_OUTPUT_MO_FILES ${TPL_OUTPUT_MO_FILES} ${output_mo_file})

    # message(STATUS "Added Susan template target ${template_file}")

endmacro(omc_add_template_target)


omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/AbsynDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/AbsynDumpTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/AbsynJLDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/AbsynDumpTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/AbsynToJulia.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/AbsynToJuliaTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCFunctions.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/DAEDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/DAEDumpTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/ExpressionDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/ExpressionDumpTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/DAEDumpTpl.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/GenerateAPIFunctionsTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/SCodeDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/AbsynDumpTpl.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/Unparsing.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCFunctions.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtilSimulation.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenEmbeddedC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCFunctions.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU2.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU3.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCommon.tpl
                        DEPENDS ${OMC_GENERATED_MO_DIR}/Template/CodegenFMUCommon.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCFunctions.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU1.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCommon.tpl
                        DEPENDS ${OMC_GENERATED_MO_DIR}/Template/CodegenFMUCommon.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU2.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCommon.tpl
                        DEPENDS ${OMC_GENERATED_MO_DIR}/Template/CodegenFMUCommon.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU3.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCommon.tpl
                        DEPENDS ${OMC_GENERATED_MO_DIR}/Template/CodegenFMUCommon.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppOMSI.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppInit.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppCommon.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppInit.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppCommon.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppHpcomOMSI.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppOMSI.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppHpcom.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCppOMSI.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppOMSI.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenOMSI_common.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtilSimulation.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCFunctions.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenOMSIC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenOMSI_common.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtilSimulation.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenOMSICpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppOMSI.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenOMSIC_Equations.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCFunctions.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtilSimulation.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCppHpcomOMSI.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCppOMSI.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppHpcomOMSI.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppCommon.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCppHpcom.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppHpcom.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppCommon.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCpp.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppInit.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCommon.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenMidToC.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/MidCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/GraphvizDump.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeBackendTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/GraphMLDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/GraphMLDumpTplTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/NFInstDumpTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/NFInstDumpTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeDump.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SCodeDumpTpl.tpl)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenXML.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenJS.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Template/VisualXMLTpl.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Template/VisualXMLTplTV.mo)

omc_add_template_target(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/susan_codegen/TplCodegen.tpl
                        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/susan_codegen/TplCodegenTV.mo)
