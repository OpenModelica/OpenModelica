
omc_add_subdirectory(runtime)
omc_add_subdirectory(boot)
omc_add_subdirectory(FrontEndCpp)


# set(OMC_EXE ${PROJECT_SOURCE_DIR}/../build/bin/omc)
set(OMC_EXE $<TARGET_FILE:bomc>)

# Enable MetaModelica debug symbols when doing a debug build, which is needed
# for the debugger to work.
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(GEN_DEBUG_SYMBOLS "-d=gendebugsymbols")
endif()

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



macro(add_interface_check_step mo_source_file)
    add_interface_checker_script(${mo_source_file})

    get_filename_component(file_name_no_ext ${mo_source_file} NAME_WLE)
    get_filename_component(source_dir ${mo_source_file} DIRECTORY)

    add_custom_command(
        DEPENDS ${mo_source_file}
                ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.check_interface.mos

        COMMAND ${OMC_EXE} -g=MetaModelica -n=1 ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.check_interface.mos

        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo.stamp
        BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo
        COMMENT "Checking interface for ${mo_source_file}"
    )

    set(OMC_MM_SOURCE_FILE_NAMES ${OMC_MM_SOURCE_FILE_NAMES} ${file_name_no_ext})

    set(OMC_MM_INTERFACE_FILES ${OMC_MM_INTERFACE_FILES} ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo)
    set(OMC_MM_STAMP_FILES ${OMC_MM_STAMP_FILES} ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo.stamp)


    add_custom_command(
        DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo
        # COMMAND ${CMAKE_COMMAND} -E cat ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.rev_depends
        COMMAND ${CMAKE_COMMAND} -DREV_DEP_FILE=${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.rev_depends
                                 -DINTERFACE_FILES_DIR=${CMAKE_CURRENT_BINARY_DIR}
                                  -P ${CMAKE_CURRENT_SOURCE_DIR}//.cmake/dep_toucher.cmake
        COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.rev_deps.stamp
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.rev_deps.stamp
        COMMENT "Touching dependents of ${mo_source_file}"
    )
    set(OMC_REV_DEP_STAMP_FILES ${OMC_REV_DEP_STAMP_FILES} ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.rev_deps.stamp)

endmacro(add_interface_check_step)




macro(add_compile_step mo_source_file)

    add_compile_script(${mo_source_file})

    get_filename_component(file_name_no_ext ${mo_source_file} NAME_WLE)
    get_filename_component(source_dir ${mo_source_file} DIRECTORY)

    add_custom_command(
        DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo.stamp
                ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.compile.mos

        COMMAND ${OMC_EXE} -g=MetaModelica -n=1 ${GEN_DEBUG_SYMBOLS} ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.compile.mos

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



add_custom_command(
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Script/OpenModelicaScriptingAPI.mos
            ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ModelicaBuiltin.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/Template/GenerateAPIFunctionsTpl.tpl

    # We want to generate OpenModelicaScriptingAPI.mo in scripts folder. Since the script
    # generates it in the current working directory we go there. Later we can fix the script to
    # take a path or change the MM source list to pick up the generated OpenModelicaScriptingAPI.mo
    # from <build_dir>/Compiler.
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Script

    COMMAND ${OMC_EXE} -g=MetaModelica -n=1 ${CMAKE_CURRENT_SOURCE_DIR}/Script/OpenModelicaScriptingAPI.mos

    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/Script/OpenModelicaScriptingAPI.mo
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/Script/OpenModelicaScriptingAPIQt.cpp
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/Script/OpenModelicaScriptingAPIQt.h
    COMMENT "Generating ${CMAKE_CURRENT_SOURCE_DIR}/Script/OpenModelicaScriptingAPI.mo using ${CMAKE_CURRENT_SOURCE_DIR}/Script/OpenModelicaScriptingAPI.mos"
)





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



# A target to make sure all interfaces have been checked. Interfaces get rechecked if a MM source is
# modified. If a source is modified and the interface has NOT actually changed then only the stamp files
# are touched to signify time of check. If the interface has CHANGED then the interface file is also
# updated which will cause regeneration of dependency information. See the section below.
add_custom_target(INTERFACE_CHECK
                  DEPENDS ${OMC_MM_STAMP_FILES}
                  COMMENT "Checked interfaces of modified MetaModelica sources.")




# Add a small dependency scanner program. This reads a list of list of dependencies and generates
# a list of dependents for each entry.
add_executable(dep_scanner ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/dep_scanner.cpp)

# Write out a new line separated list of all MM source files to a list so that it can be easily
# parsed by the small MetaModelica dependency scanner we have now. (c++ code)
# The quote "" on ${OMC_MM_SOURCE_FILE_NAMES} is needed to get the ";"s in the list
string (REPLACE ";" "\n" OMC_MM_SOURCE_FILE_NAMES_NEW_LINES "${OMC_MM_SOURCE_FILE_NAMES}")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/mm_source_filenames_list.txt ${OMC_MM_SOURCE_FILE_NAMES_NEW_LINES})

# Read the mm_source_filenames_list with the dep scanner. The dep scanner then reads <mm_source>.depends file for the
# each mm_source in the list and generates the "reverse dependencies" (dependents) for each source in to <mm_source>.rev_deps.
# This means all the files listed in .rev_deps need to be retranslated when <mm_source>.mo is modified.
add_custom_command(
                DEPENDS ${OMC_MM_INTERFACE_FILES}
                COMMAND $<TARGET_FILE:dep_scanner> ${CMAKE_CURRENT_BINARY_DIR}/mm_source_filenames_list.txt ${CMAKE_CURRENT_BINARY_DIR}
                COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/dep_scan.stamp
                OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/dep_scan.stamp
                COMMENT "Scanning reverse dependencies for MetaModelica sources.")
add_custom_target(DEPENDENCY_SCAN
                  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/dep_scan.stamp
                  COMMENT "Scanned reverse dependencies for MetaModelica sources.")





add_custom_target(DEPENDENCY_UPDATE
                  DEPENDS ${OMC_REV_DEP_STAMP_FILES}
                  COMMENT "Touched dependents of modified MetaModelica sources.")


add_dependencies(DEPENDENCY_SCAN INTERFACE_CHECK)
add_dependencies(DEPENDENCY_UPDATE DEPENDENCY_SCAN)




add_library(OpenModelicaCompiler SHARED ${OMC_C_SOURCE_FILES} .cmake/omc_entry_point.c)
add_dependencies(OpenModelicaCompiler DEPENDENCY_UPDATE)

# output libOpenModelicaCompiler in a directory named 'lib' or 'bin' (on Windows, dll) inside
# the current binary directory. The reason for this is that omc (using libOpenModelicaCompiler),
# up on launch, checks where it is located and looks for the things it wants relative to that location.
# For example it expects ModelicaBuiltin.mo to be in '../lib/omc' relative to the libOpenModelicaCompiler shared
# library. To achieve this it first checks if libOpenModelicaCompiler is a directory named 'bin' or 'lib'.
# If it is not it will refuse to run. So output it in a directory named 'lib' or 'bin' and then copy
# The files it needs in '../lib/omc' relative to it.
set_target_properties(OpenModelicaCompiler
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)

# It also wants to have these builtin files in ../lib/ relative to its location.
add_custom_command (
    TARGET OpenModelicaCompiler
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/AnnotationsBuiltin_1_x.mo ${CMAKE_CURRENT_BINARY_DIR}/lib/omc/AnnotationsBuiltin_1_x.mo
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/AnnotationsBuiltin_2_x.mo ${CMAKE_CURRENT_BINARY_DIR}/lib/omc/AnnotationsBuiltin_2_x.mo
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/AnnotationsBuiltin_3_x.mo ${CMAKE_CURRENT_BINARY_DIR}/lib/omc/AnnotationsBuiltin_3_x.mo
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/lib/omc/ModelicaBuiltin.mo
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/MetaModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/lib/omc/MetaModelicaBuiltin.mo
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/lib/omc/NFModelicaBuiltin.mo
    COMMENT "Copying (NF/Meta/Modelica)Builtin.mo files for the omc generated in the build tree (not installed yet).")


target_compile_definitions(OpenModelicaCompiler PRIVATE ADD_METARECORD_DEFINITIONS=)

# Silence warnings about extra parenthesized equality checks. if((a==b))
if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
  target_compile_options(OpenModelicaCompiler PRIVATE -Wno-parentheses-equality)
endif()

# Silence GCC warnings about invalid reads of MetaModelica strings.
if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  target_compile_options(OpenModelicaCompiler PRIVATE -Wno-stringop-overread)
endif()

# There is a lonely omc_file.h in Util/. It belongs in runtime/. Remove this when it is moved.
target_include_directories(OpenModelicaCompiler PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/Util)

# This should not be needed ideally. However linking libs sometimes need to include the generated headers.
# Right now this only happens for OMEdit. OMEdit includes Script/OpenModelicaScriptingAPIQt.h
# which in turn wants to include OpenModelicaScriptingAPI.h. This header is generated from
# translation of OpenModelicaScriptingAPI.mo. So this interface include dir is needed.
# We can maybe copy these headers to some specific location after generation and avoid this.
target_include_directories(OpenModelicaCompiler INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/c_files)

# OMC will overflow the stack (at least on Windows old OMDev) on very deep recursive calls.
# E.g., try translating the CodegenCpp* tpl files to mo files with
# an omc not compiled without large stack size. The tpl parser is quite recursive and will
# overflow on parsing comments with very long lines ~300. *CPP tpl files have lines longer
# than that.
# if(MINGW)
#   target_link_options(OpenModelicaCompiler PUBLIC -Wl,--stack,33554432)
# endif()

# For now disable some warnings for MSVC. These should of course be fixed properly.
if(MSVC)
  target_compile_options(OpenModelicaCompiler PRIVATE /wd4101) # unreferenced local variable
  target_compile_options(OpenModelicaCompiler PRIVATE /wd4102) # unreferenced label
  target_compile_options(OpenModelicaCompiler PRIVATE /wd4267) # conversion from 'size_t' to 'int', possible loss of data
  target_compile_options(OpenModelicaCompiler PRIVATE /wd4244) # conversion from '' to '', possible loss of data
endif()



target_link_libraries(OpenModelicaCompiler PUBLIC omc::parser)
target_link_libraries(OpenModelicaCompiler PUBLIC omc::compiler::backendruntime)
target_link_libraries(OpenModelicaCompiler PUBLIC omc::compiler::runtime)
target_link_libraries(OpenModelicaCompiler PUBLIC omc::compiler::frontendcpp)
target_link_libraries(OpenModelicaCompiler PUBLIC omc::simrt::runtime)

# On Windows we need explicitly tell the dll to export all symbols. It is not so good
# that we have to export all symbols. However, OMEdit uses some of the functions in the
# lib directly and we have no way of marking specific MetaModelica functions for exporting.
if(MINGW)
  target_link_options(OpenModelicaCompiler PRIVATE  -Wl,--export-all-symbols)
elseif(MSVC)
  set_target_properties(OpenModelicaCompiler PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif()

# OMC Executable.
add_executable(omc .cmake/omc_main.c)
target_link_libraries(omc PRIVATE OpenModelicaCompiler)

if(NOT WIN32)
  target_link_options(omc PRIVATE -rdynamic)
endif()

# if(MINGW)
#   target_link_options(omc PRIVATE -Wl,--stack,33554432)
# endif()



### INSTALLATION

# Install OpenModelicaCompiler to the directory for LIBRARIES (default=lib)
# Install omc to the directory for RUNTIME (default=bin)
# They are part of "compiler" installation component. This means that you can
# install just the files in this component by specifying its name.
if(WIN32)
  # Escape the environment variable path
  if(NOT DEFINED ENV{OMDEV})
    message(FATAL_ERROR "Environment variable \"OMDEV\" is not set.")
  endif()
  if(NOT DEFINED ENV{MSYSTEM_PREFIX})
    message(FATAL_ERROR "Environment variable \"MSYSTEM_PREFIX\" is not set.")
  endif()

  if (CMAKE_GENERATOR STREQUAL "MinGW Makefiles" AND "$ENV{VisualStudioVersion}" STREQUAL "")
    string(REPLACE "\\" "/" MSYSTEM_PREFIX_ESCAPED "$ENV{OMDEV}\\tools\\msys\\$ENV{MSYSTEM_PREFIX}")
  else()
    string(REPLACE "\\" "/" MSYSTEM_PREFIX_ESCAPED "$ENV{MSYSTEM_PREFIX}")
  endif()

  set(OMCOMPILER_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMCompiler/Compiler/bin)
  set(SIMULATION_RUNTIME_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMCompiler/SimulationRuntime/c)
  set(GC_RUNTIME_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMCompiler/3rdParty/gc)
  set(RUNTIME_LIB_DIRS ${OMPLOT_LIB_DIR} ${OMSIMULATOR_LIB_DIR} ${OMCOMPILER_LIB_DIR} ${SIMULATION_RUNTIME_LIB_DIR} ${GC_RUNTIME_LIB_DIR})

  message(STATUS "Looking for runtime dependencies of OpenModelicaCompiler in ${MSYSTEM_PREFIX_ESCAPED}/bin ${RUNTIME_LIB_DIRS}")
  install(TARGETS OpenModelicaCompiler
          RUNTIME_DEPENDENCIES
            DIRECTORIES ${MSYSTEM_PREFIX_ESCAPED}/bin ${RUNTIME_LIB_DIRS}
            PRE_EXCLUDE_REGEXES "api-ms-" "ext-ms-"
            POST_EXCLUDE_REGEXES ".*system32/.*\\.dll")
  install(TARGETS omc
          COMPONENT omc)
else(WIN32)
  install(TARGETS omc OpenModelicaCompiler
          COMPONENT omc)
endif(WIN32)

# Install the *ModelicaBuiltin files to <library_dir>/omc/ that is where omc.exe expects them to be.
# They are also part of "compiler" installation component.
install(FILES FrontEnd/AnnotationsBuiltin_1_x.mo
            DESTINATION lib/omc
            COMPONENT omc)
install(FILES FrontEnd/AnnotationsBuiltin_2_x.mo
            DESTINATION lib/omc
            COMPONENT omc)
install(FILES FrontEnd/AnnotationsBuiltin_3_x.mo
            DESTINATION lib/omc
            COMPONENT omc)
install(FILES NFFrontEnd/NFModelicaBuiltin.mo
            DESTINATION lib/omc
            COMPONENT omc)
install(FILES FrontEnd/ModelicaBuiltin.mo
            DESTINATION lib/omc
            COMPONENT omc)
install(FILES FrontEnd/MetaModelicaBuiltin.mo
            DESTINATION lib/omc
            COMPONENT omc)
install(FILES FrontEnd/PDEModelicaBuiltin.mo
            DESTINATION lib/omc
            COMPONENT omc)

# Install the scripts to 'share' dir.
install(DIRECTORY scripts
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omc/)


# This is a convenience target to install omc. We are used to issuing 'make install' to install
# components. CMake uses a separate install script to perform installations. This custom command
# runs that cmake script so that you can just write 'make install' (for makefile generators)
# or 'cmake --build <b_dir> --target install_omc' in the general case.
add_custom_target(install_omc
                  DEPENDS omc
                  COMMAND ${CMAKE_COMMAND} -DCOMPONENT=compiler -P cmake_install.cmake
                  COMMENT "Installing omc."
                  )
