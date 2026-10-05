# Regeneration of the bootstrapping sources kept in OMCompiler/Compiler/boot/bomc
# (the OMBootstrapping submodule).
#
# bomc is built from pre-translated C sources instead of from the MetaModelica
# sources, which is what breaks the chicken-and-egg problem of needing an omc to
# build omc. Those C sources are a snapshot of what the compiler generates for
# its own sources and have to be refreshed whenever bomc is too old to translate
# the current Compiler/*.mo (new MetaModelica syntax, new builtins, ...).
#
#   cmake --build <build_dir> --target update-bootstrap-sources
#
# translates the compiler a second time and copies the result into the submodule
# working tree, ready to be committed and PR'd to OMBootstrapping.
#
# Why a second translation instead of just copying <build_dir>/c_files:
# every sourceInfo() in the compiler is constant folded into a SourceInfo literal
# in the generated C, and its fileName is the absolute path of the .mo. A plain
# copy would therefore embed the checkout of whoever ran the build, which is
# noise in every diff and makes the snapshot unreproducible. Setting
# OPENMODELICA_BACKEND_STUBS=1 makes Parser/parse.c store the basename instead
# (members.filename_C_testsuiteFriendly). It is deliberately *not* set for the
# normal build: that would strip the paths out of the shipped compiler's own
# error and failtrace messages too.
# The other half of that literal, the mtime of the .mo, is pinned to 0.0 by
# Static.elabBuiltinSourceInfo for every build (OpenModelica#14399), so it needs
# no flag here.
#
# The interface files (<name>.interface.mo, <name>.public.imports) do not depend
# on that flag, so this reuses the ones the normal build already produced rather
# than checking every interface twice.
#
# The other source of build-location dependent output is Susan: it writes the
# path of the .tpl it was given into the generated .mo as a literal string, which
# no parser flag can undo afterwards. .cmake/template_compilation.cmake therefore
# invokes it with a path relative to the template's own directory.

set(OMC_BOOTSTRAP_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/bootstrap-sources)
# Mirror the layout of the submodule: bootstrap-sources/build/*.c
set(OMC_BOOTSTRAP_C_DIR ${OMC_BOOTSTRAP_BINARY_DIR}/build)
set(OMC_BOOTSTRAP_TARBALL_INCLUDE_DIR ${OMC_BOOTSTRAP_BINARY_DIR}/tarball-include)
set(OMC_BOOTSTRAP_BOMC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/boot/bomc)

# The snapshot is generated with the compiler that was just built, not with the
# bomc used for the rest of this build. The whole point of updating it is to hand
# the next generation of bomc whatever the current compiler emits.
set(OMC_BOOTSTRAP_OMC $<TARGET_FILE:omc>)

# Never pass ${GEN_DEBUG_SYMBOLS} here. It changes the generated C, and the
# snapshot must not depend on the CMAKE_BUILD_TYPE of the tree it was made in.
# ${CHECK_DEF_USE} on the other hand is a static check that leaves the output
# alone, and is kept so this pass rejects exactly what the normal build rejects.

macro(add_bootstrap_compile_step mo_source_file)

    get_filename_component(file_name_no_ext ${mo_source_file} NAME_WLE)
    get_filename_component(source_dir ${mo_source_file} DIRECTORY)

    set(MM_PACKAGE_NAME ${file_name_no_ext})
    set(MM_INPUT_SOURCE_DIR ${source_dir})
    # Read the interfaces from the normal build tree, write the C to ours.
    set(MM_OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
    set(MM_C_OUTPUT_DIR ${OMC_BOOTSTRAP_C_DIR})
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/.cmake/mm_compile.in.mos
                   ${OMC_BOOTSTRAP_BINARY_DIR}/${file_name_no_ext}.compile.mos)

    add_custom_command(
        DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${file_name_no_ext}.interface.mo.stamp
                ${OMC_BOOTSTRAP_BINARY_DIR}/${file_name_no_ext}.compile.mos

        COMMAND ${CMAKE_COMMAND} -E env OPENMODELICA_BACKEND_STUBS=1
                ${OMC_BOOTSTRAP_OMC} -g=MetaModelica -n=1 ${CHECK_DEF_USE}
                ${OMC_BOOTSTRAP_BINARY_DIR}/${file_name_no_ext}.compile.mos

        OUTPUT  ${OMC_BOOTSTRAP_C_DIR}/${file_name_no_ext}.c
                ${OMC_BOOTSTRAP_C_DIR}/${file_name_no_ext}_records.c
                ${OMC_BOOTSTRAP_C_DIR}/${file_name_no_ext}.h
                ${OMC_BOOTSTRAP_C_DIR}/${file_name_no_ext}_includes.h

        BYPRODUCTS ${OMC_BOOTSTRAP_C_DIR}/${file_name_no_ext}.deps

        COMMENT "Translating ${mo_source_file} for the bootstrapping sources"
    )

    set(OMC_BOOTSTRAP_C_FILES ${OMC_BOOTSTRAP_C_FILES}
        ${OMC_BOOTSTRAP_C_DIR}/${file_name_no_ext}.c
        ${OMC_BOOTSTRAP_C_DIR}/${file_name_no_ext}_records.c)
endmacro(add_bootstrap_compile_step)


# The snapshot covers everything the compiler is made of, backend included. bomc
# does not link the external C implementations of the backend, which is what
# bootstrap-sources/build/FakeBoostrappingExternals.c in the submodule is for. It
# is hand written and left untouched by the update.
foreach(OMC_MM_SOURCE ${OMC_MM_ALWAYS_SOURCES} ${OMC_MM_BACKEND_SOURCES})
    add_bootstrap_compile_step(${OMC_MM_SOURCE})
endforeach()


# _main.c holds __omc_main(), the entry point calling Main.main. bomc pairs it
# with .cmake/omc_main.c, which supplies main() itself.
# GenerateEntryPoint.mos writes to the relative path "build/_main.c", hence the
# working directory one level above the C output directory.
add_custom_command(
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/boot/GenerateEntryPoint.mos

    WORKING_DIRECTORY ${OMC_BOOTSTRAP_BINARY_DIR}

    COMMAND ${CMAKE_COMMAND} -E make_directory ${OMC_BOOTSTRAP_C_DIR}
    COMMAND ${CMAKE_COMMAND} -E env OPENMODELICA_BACKEND_STUBS=1
            ${OMC_BOOTSTRAP_OMC} -g=MetaModelica
            ${CMAKE_CURRENT_SOURCE_DIR}/boot/GenerateEntryPoint.mos

    OUTPUT ${OMC_BOOTSTRAP_C_DIR}/_main.c
    COMMENT "Generating _main.c for the bootstrapping sources"
)


# OpenModelicaBootstrappingHeader.h declares the records the runtime shares with
# the compiler. boot/CMakeLists.txt copies the submodule's copy back into
# Compiler/ at configure time, so it has to be refreshed along with the C.
# GenerateOMCHeader.mos loads its inputs by relative path and writes
# OpenModelicaBootstrappingHeader.h.new next to them, so it has to run in
# Compiler/; the .new file is removed again right after.
# The header is nothing but record descriptions, no SourceInfo and therefore no
# paths or timestamps, so OPENMODELICA_BACKEND_STUBS makes no difference here.
add_custom_command(
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/GenerateOMCHeader.mos
            ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Absyn.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/Script/GlobalScript.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Values.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/Util/ErrorTypes.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/Util/Config.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/Util/FMI.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFType.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFExpression.mo
            ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFDimension.mo

    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}

    COMMAND ${OMC_BOOTSTRAP_OMC} -g=MetaModelica ${CMAKE_CURRENT_SOURCE_DIR}/GenerateOMCHeader.mos
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/OpenModelicaBootstrappingHeader.h.new
            ${OMC_BOOTSTRAP_TARBALL_INCLUDE_DIR}/OpenModelicaBootstrappingHeader.h
    COMMAND ${CMAKE_COMMAND} -E remove -f ${CMAKE_CURRENT_SOURCE_DIR}/OpenModelicaBootstrappingHeader.h.new

    OUTPUT ${OMC_BOOTSTRAP_TARBALL_INCLUDE_DIR}/OpenModelicaBootstrappingHeader.h
    BYPRODUCTS ${CMAKE_CURRENT_SOURCE_DIR}/OpenModelicaBootstrappingHeader.h.new
    COMMENT "Generating OpenModelicaBootstrappingHeader.h for the bootstrapping sources"
)


# Generate only. Useful on its own to check that the snapshot can be produced
# without touching the submodule working tree.
add_custom_target(generate-bootstrap-sources
                  DEPENDS ${OMC_BOOTSTRAP_C_FILES}
                          ${OMC_BOOTSTRAP_C_DIR}/_main.c
                          ${OMC_BOOTSTRAP_TARBALL_INCLUDE_DIR}/OpenModelicaBootstrappingHeader.h
                  COMMENT "Generated the bootstrapping sources in ${OMC_BOOTSTRAP_C_DIR}.")

# omc pulls in DEPENDENCY_UPDATE, and with it every interface this pass reads.
add_dependencies(generate-bootstrap-sources omc DEPENDENCY_UPDATE)


add_custom_target(update-bootstrap-sources
                  COMMAND ${CMAKE_COMMAND}
                          -DBOOTSTRAP_C_DIR=${OMC_BOOTSTRAP_C_DIR}
                          -DBOOTSTRAP_HEADER=${OMC_BOOTSTRAP_TARBALL_INCLUDE_DIR}/OpenModelicaBootstrappingHeader.h
                          -DBOMC_DIR=${OMC_BOOTSTRAP_BOMC_DIR}
                          -P ${CMAKE_CURRENT_SOURCE_DIR}/.cmake/sync_bootstrap_sources.cmake
                  COMMENT "Updating OMCompiler/Compiler/boot/bomc from the generated bootstrapping sources")

add_dependencies(update-bootstrap-sources generate-bootstrap-sources)
