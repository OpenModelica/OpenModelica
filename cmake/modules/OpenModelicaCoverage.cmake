# Code coverage for the OpenModelica compiler, the C/C++ simulation runtimes,
# the FMU export sources and OMEdit, enabled with -DOM_ENABLE_COVERAGE=ON.
#
# Instrumentation is applied where the sources are, so that everything defined
# in or below those directories is covered:
#   OMCompiler/Compiler/CMakeLists.txt          (the OpenModelicaCompiler target)
#   OMCompiler/SimulationRuntime/c/CMakeLists.txt
#   OMCompiler/SimulationRuntime/cpp/CMakeLists.txt
#   OMCompiler/SimulationRuntime/fmi/export/buildproject/CMakeLists.txt
#   OMEdit/OMEditLIB/CMakeLists.txt             (the OMEditLib target)
#
# FMU export sources: fmu2_model_interface.c and friends are never compiled by
# this build. omc copies them into every FMU it exports, and the FMU's own
# CMake project compiles them there. A coverage build therefore installs an FMU
# project template that instruments them (see Coverage.cmake.in next to it).
# omc deletes the FMU's build directory as soon as the FMU is packed, so their
# notes (*.gcno) and counters (*.gcda) go to a directory of their own,
# OM_COVERAGE_FMU_DIR below, or $OMC_COVERAGE_FMU_DIR when the FMU is built.
# The copies are gone by the time the report is written too, so they are
# compiled with a #line naming the original in this source tree, which is what
# gcov then reads and reports.
#
# MetaModelica coverage: the compiler is written in MetaModelica, which omc
# translates to C before anything is compiled, so gcov would normally only ever
# see the generated build_cmake/.../c_files/*.c. To get coverage of the .mo
# sources instead, a coverage build also turns on omc's -d=gendebugsymbols (see
# OMCompiler/Compiler/CMakeLists.txt): the code generator then emits
# /*#modelicaLine <file>:<line>*/ markers, which Print turns into C `#line`
# directives naming the .mo file. gcov follows those, so NFFlatten.mo and
# friends are what show up in the report. Filtering on the source tree below
# keeps the leftover generated C - boilerplate with no #line of its own - out
# of the report.
#
# This module has to be included before the instrumented subdirectories are.

omc_option(OM_ENABLE_COVERAGE "Instrument the compiler and the C/C++ simulation runtimes for gcov code coverage. Needs GCC or Clang and gcovr." OFF)

if(NOT OM_ENABLE_COVERAGE)
  return()
endif()

if(NOT CMAKE_C_COMPILER_ID MATCHES "GNU|Clang" OR NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  message(FATAL_ERROR "OM_ENABLE_COVERAGE needs GCC or Clang for both C and C++, but got "
                       "C=${CMAKE_C_COMPILER_ID} CXX=${CMAKE_CXX_COMPILER_ID}.")
endif()

find_program(GCOVR_EXECUTABLE gcovr)
if(NOT GCOVR_EXECUTABLE)
  message(FATAL_ERROR "OM_ENABLE_COVERAGE needs gcovr, which was not found. "
                       "Install it with 'pip install gcovr' or your package manager.")
endif()

# Atomic counters because omc and parts of the simulation runtimes are
# multithreaded, and threads share a translation unit's counters: without atomic
# updates, concurrent increments are lost. Separate processes need no such care -
# each keeps its own counters, and libgcov merges them into the .gcda file at
# exit - so neither ctest -j nor the number of CI stages is a reason for this.
#
# The build type's optimization level is deliberately left alone. -O0 gives
# more precise line attribution (no inlining), but omc and the simulation
# runtime are on the hot path of every single test, so an unoptimized coverage
# build makes a testsuite run far slower. Add -O0 here if you are chasing exact
# per-line numbers and can afford it.
set(OM_COVERAGE_COMPILE_OPTIONS "--coverage;-fprofile-update=atomic" CACHE STRING
    "Compile options used to instrument the covered sources")

# Switches openmodelica.h's EXIT() macro to dump the gcov counters before it
# calls _exit(), which otherwise skips the atexit handler that writes them -
# omc ends in EXIT(0), so without this it records nothing at all. Deliberately
# not part of OM_COVERAGE_COMPILE_OPTIONS above: that is a tunable cache
# variable, and overriding it must not silently turn this off. Set here, ahead
# of every subdirectory, so it reaches the runtimes and the compiler alike.
add_compile_definitions(OMC_GCOV_COVERAGE)

# The generated MetaModelica lives under the build tree, so the compiler
# records it in the .gcno relative to the directory it compiled in. gcov is
# run from the object directory, where that relative path does not resolve,
# and the template modules would silently drop out of the report. Recording
# absolute paths instead fixes it.
#
# Only for C and C++: the options are the C/C++ compiler's, while Fortran
# (MUMPS, RADAU, ...) is compiled by gfortran whichever of the two that is,
# and gfortran rejects clang's. Nothing in Fortran is instrumented anyway.
# (CMake 3.14 has no COMPILE_LANGUAGE:C,CXX yet.)
set(_om_coverage_c_or_cxx "$<OR:$<COMPILE_LANGUAGE:C>,$<COMPILE_LANGUAGE:CXX>>")
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
  add_compile_options("$<${_om_coverage_c_or_cxx}:-fprofile-abs-path>")
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  # Clang has no -fprofile-abs-path. It records a path relative to the
  # compilation directory whenever the file is below it, and absolute
  # otherwise - so pointing the recorded compilation directory at somewhere
  # nothing is built under leaves every path absolute. The directory is never
  # read or created; it only has to not be a parent of the sources.
  #
  # It also sets the compilation directory in the debug info (DW_AT_comp_dir),
  # which is only consulted to resolve *relative* paths - and there are none
  # left once this is in effect.
  set(OM_COVERAGE_CLANG_COMPILATION_DIR "${CMAKE_SOURCE_DIR}/.omc-coverage-abs-paths"
      CACHE STRING "Recorded compilation directory that keeps Clang's coverage paths absolute")
  add_compile_options("$<${_om_coverage_c_or_cxx}:-ffile-compilation-dir=${OM_COVERAGE_CLANG_COMPILATION_DIR}>")
else()
  message(WARNING
    "OM_ENABLE_COVERAGE with ${CMAKE_C_COMPILER_ID}: the Susan-generated "
    "template modules (build tree generated-mo/*Tpl.mo) will be missing from "
    "the coverage report, because there is no known way to make this compiler "
    "record the absolute paths gcov needs for them. Coverage of everything "
    "that lives in the source tree - the compiler, both runtimes - is "
    "unaffected.")
endif()

# Clang writes gcov data, but only its own llvm-cov can read it back.
if(CMAKE_C_COMPILER_ID MATCHES "Clang")
  set(_default_gcov "llvm-cov gcov")
else()
  set(_default_gcov "gcov")
endif()
set(OM_COVERAGE_GCOV "${_default_gcov}" CACHE STRING
    "The gcov tool gcovr uses; has to match the compiler that built the sources")

set(OM_COVERAGE_DIR "${CMAKE_BINARY_DIR}/coverage")
set(OM_COVERAGE_TITLE
    "${CMAKE_SYSTEM_NAME} ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION} Code Coverage Report"
    CACHE STRING "Title of the generated HTML coverage report")

# Source-tree paths: the generated C lives under the build directory and is
# filtered out by not being listed here.
#
# Narrow it to what a run actually exercises when its tracefile is merged with
# others (see OM_COVERAGE_TRACEFILES): a build instruments everything, so a
# tracefile also lists every line of the sources its tests never ran. Where
# the other builds' compilers or optimization levels record different lines
# for the same source, those lines only add to the total, never to the hits -
# the C runtime unit tests would otherwise add a hundred thousand uncovered
# lines of compiler to the report.
set(OM_COVERAGE_SOURCE_DIRS
    "OMCompiler/Compiler/;OMCompiler/SimulationRuntime/c/;OMCompiler/SimulationRuntime/cpp/;OMCompiler/SimulationRuntime/fmi/export/openmodelica/;OMEdit/OMEditLIB/"
    CACHE STRING "Source directories, relative to the source tree, whose coverage coverage-collect reports")
set(_om_coverage_filter_args)
foreach(_filter IN LISTS OM_COVERAGE_SOURCE_DIRS)
  list(APPEND _om_coverage_filter_args --filter "${CMAKE_SOURCE_DIR}/${_filter}")
endforeach()

# The originals of the FMU export sources, which the instrumented FMUs name in
# their #line (see Coverage.cmake.in), and where exported FMUs keep their notes
# and counters, one subdirectory per FMU build. The latter below the build
# directory, so that coverage-collect finds them.
set(OM_COVERAGE_FMU_EXPORT_DIR "${CMAKE_SOURCE_DIR}/OMCompiler/SimulationRuntime/fmi/export/openmodelica")
set(OM_COVERAGE_FMU_DIR "${CMAKE_BINARY_DIR}/coverage-fmu")

# The one build-tree exception: the MetaModelica Susan generates from the
# *.tpl templates. Without it the code generator is missing from the report
# entirely. OpenModelicaCoverageTemplates.py additionally maps this back onto
# the *.tpl themselves, per template.
if("OMCompiler/Compiler/" IN_LIST OM_COVERAGE_SOURCE_DIRS)
  list(APPEND _om_coverage_filter_args
       --filter "${CMAKE_BINARY_DIR}/OMCompiler/Compiler/generated-mo/")
endif()

set(OM_COVERAGE_TEMPLATE_DIR "${CMAKE_SOURCE_DIR}/OMCompiler/Compiler/Template")
set(OM_COVERAGE_GENERATED_MO_DIR "${CMAKE_BINARY_DIR}/OMCompiler/Compiler/generated-mo/Template")

# Needed by coverage-report (the template mapping) and coverage-serve below.
find_package(Python3 COMPONENTS Interpreter REQUIRED)

# Clang and the compiler's MetaModelica: LLVM's gcov instrumentation drops
# every line whose #line names another file than its function's - all of the
# MetaModelica in the generated C. So the compiler's generated C is compiled
# without its #line directives (omc_coverage_line_directives_launcher() below)
# and covered as C, and OpenModelicaCoverageLineDirectives.py moves that onto
# the MetaModelica after gcovr has collected it, by replaying the directives.
# The generated C has to be there for that; the entries for it are dropped
# again.
set(_OM_COVERAGE_MODULE_DIR "${CMAKE_CURRENT_LIST_DIR}")
function(omc_coverage_line_directives_launcher target c_files_dir)
  if(CMAKE_C_COMPILER_ID MATCHES "Clang")
    set_property(TARGET ${target} PROPERTY C_COMPILER_LAUNCHER
                 "${Python3_EXECUTABLE}"
                 "${_OM_COVERAGE_MODULE_DIR}/OpenModelicaCoverageClangLauncher.py"
                 --c-files-dir "${c_files_dir}" -- ${CMAKE_C_COMPILER_LAUNCHER})
  endif()
endfunction()

set(_om_coverage_line_directive_commands)
if(CMAKE_C_COMPILER_ID MATCHES "Clang" AND "OMCompiler/Compiler/" IN_LIST OM_COVERAGE_SOURCE_DIRS)
  set(OM_COVERAGE_C_FILES_DIR "${CMAKE_BINARY_DIR}/OMCompiler/Compiler/c_files")
  list(APPEND _om_coverage_filter_args --filter "${OM_COVERAGE_C_FILES_DIR}/")
  set(_om_coverage_line_directive_commands
      COMMAND ${Python3_EXECUTABLE}
              "${CMAKE_CURRENT_LIST_DIR}/OpenModelicaCoverageLineDirectives.py"
              --gcovr-json "${OM_COVERAGE_DIR}/coverage.json"
              --c-files-dir "${OM_COVERAGE_C_FILES_DIR}"
              --root "${CMAKE_SOURCE_DIR}"
              ${_om_coverage_filter_args})
endif()

file(RELATIVE_PATH _report_path "${CMAKE_BINARY_DIR}" "${OM_COVERAGE_DIR}/index.html")

add_custom_target(coverage-reset
                  COMMAND ${CMAKE_COMMAND} -DOM_COVERAGE_BINARY_DIR=${CMAKE_BINARY_DIR}
                          -DOM_COVERAGE_FMU_DIR=${OM_COVERAGE_FMU_DIR}
                          -P "${CMAKE_CURRENT_LIST_DIR}/OpenModelicaCoverageReset.cmake"
                  COMMENT "Discarding previously collected coverage data"
                  VERBATIM)

# gcovr 8 rejects a line hit more often than a threshold as "suspicious": GCC
# bug 68080 turns racing counter updates into garbage counts, and gcovr aborts
# the whole report on the first one. Here the counters are atomic
# (-fprofile-update=atomic), so large counts are real - the array indexing in
# base_array.c alone runs well past ten billion times over the testsuite. Raise
# the threshold far above anything a real run reaches rather than turning the
# check off, so the near-2^64 values that bug actually produces still get caught.
# Older gcovr (7.x) has neither the check nor the option, and rejects options it
# does not know, so only pass it where gcovr offers it.
execute_process(COMMAND ${GCOVR_EXECUTABLE} --help
                OUTPUT_VARIABLE _om_gcovr_help
                ERROR_QUIET)
set(_om_coverage_gcovr_threshold_args)
if(_om_gcovr_help MATCHES "--gcov-suspicious-hits-threshold")
  list(APPEND _om_coverage_gcovr_threshold_args
       --gcov-suspicious-hits-threshold 281474976710656) # 2^48
endif()

include(ProcessorCount)
ProcessorCount(_om_coverage_jobs)
if(_om_coverage_jobs EQUAL 0)
  set(_om_coverage_jobs 1)
endif()

# Collects the counters into gcovr JSON tracefiles, without rendering them:
# coverage.json, and templates.json with the part of it that is mapped onto
# the *.tpl. Kept apart from the rendering below so that tracefiles collected
# from other builds - another compiler, another testsuite run - can be merged
# into one report (see OM_COVERAGE_TRACEFILES).
add_custom_target(coverage-collect
                  COMMAND ${CMAKE_COMMAND} -E make_directory "${OM_COVERAGE_DIR}"
                  COMMAND ${GCOVR_EXECUTABLE}
                          --root "${CMAKE_SOURCE_DIR}"
                          ${_om_coverage_filter_args}
                          --gcov-executable "${OM_COVERAGE_GCOV}"
                          -j ${_om_coverage_jobs}
                          # The compiler's own view of a translation unit is
                          # the *generated* c_files/*.c, which gcov also wants
                          # to read. It is a build artifact that is filtered
                          # out of the report anyway, so gcov is allowed to not
                          # find it - otherwise it gives up on the .gcda
                          # entirely and the .mo coverage inside it is lost
                          # too. Allowing it is not enough, though: GCC's gcov
                          # still loses the .mo data of most modules then, so
                          # where the report is produced somewhere else than
                          # the build (as in CI), bring the generated C along.
                          # The same goes for the copies of the FMU export
                          # sources, deleted along with the FMU's build.
                          # Both categories show up for this: which one gcov
                          # reports depends on whether it managed to pick a
                          # working directory before giving up on the file.
                          --gcov-ignore-errors=source_not_found
                          --gcov-ignore-errors=no_working_dir_found
                          # An inline function in a header is reported at
                          # different lines by the translation units that
                          # included it (mmc_init, initializeNLScsvData, ...).
                          # gcovr's default 'strict' treats that as an error,
                          # gives up on the file, and retries in every
                          # candidate working directory - littering each one
                          # with leftover .gcov files on the way.
                          --merge-mode-functions=merge-use-line-min
                          # Large but real counts; see above.
                          ${_om_coverage_gcovr_threshold_args}
                          --exclude-unreachable-branches
                          --exclude-throw-branches
                          --print-summary
                          --json "${OM_COVERAGE_DIR}/coverage.json"
                          "${CMAKE_BINARY_DIR}"
                  # Before the template mapping, which needs the .mo lines.
                  ${_om_coverage_line_directive_commands}
                  COMMAND ${Python3_EXECUTABLE}
                          "${CMAKE_CURRENT_LIST_DIR}/OpenModelicaCoverageTemplates.py"
                          --gcovr-json "${OM_COVERAGE_DIR}/coverage.json"
                          --generated-mo-dir "${OM_COVERAGE_GENERATED_MO_DIR}"
                          --template-dir "${OM_COVERAGE_TEMPLATE_DIR}"
                          --root "${CMAKE_SOURCE_DIR}"
                          --output "${OM_COVERAGE_DIR}/templates.json"
                  COMMENT "Collecting the coverage counters into ${OM_COVERAGE_DIR}"
                  VERBATIM)

# The tracefiles the report is rendered from. Glob patterns are fine, gcovr
# expands them. The paths inside a tracefile are relative to the source tree
# it was collected in, so tracefiles collected in other checkouts of the same
# sources can be listed here too.
set(OM_COVERAGE_TRACEFILES "${OM_COVERAGE_DIR}/coverage.json;${OM_COVERAGE_DIR}/templates.json"
    CACHE STRING "gcovr JSON tracefiles coverage-html renders into one report")
set(_om_coverage_tracefile_args)
foreach(_tracefile IN LISTS OM_COVERAGE_TRACEFILES)
  list(APPEND _om_coverage_tracefile_args --add-tracefile "${_tracefile}")
endforeach()

set(_om_coverage_render_commands
    # Not there yet when the tracefiles were all collected elsewhere.
    COMMAND ${CMAKE_COMMAND} -E make_directory "${OM_COVERAGE_DIR}"
    COMMAND ${GCOVR_EXECUTABLE}
            --root "${CMAKE_SOURCE_DIR}"
            ${_om_coverage_tracefile_args}
            # Tracefiles of different compilers disagree on the line of
            # a function now and then; see coverage-collect.
            --merge-mode-functions=merge-use-line-min
            --print-summary
            --html-title "${OM_COVERAGE_TITLE}"
            --html-details "${OM_COVERAGE_DIR}/index.html"
            --cobertura "${OM_COVERAGE_DIR}/coverage.xml"
            --cobertura-pretty)

# Renders OM_COVERAGE_TRACEFILES as they are.
add_custom_target(coverage-html
                  ${_om_coverage_render_commands}
                  COMMENT "Writing the coverage report to ${_report_path}"
                  VERBATIM)

# Collects and renders in one go.
add_custom_target(coverage-report
                  ${_om_coverage_render_commands}
                  COMMENT "Writing the coverage report to ${_report_path}"
                  VERBATIM)
add_dependencies(coverage-report coverage-collect)

# Serve the report so it can be opened in a browser, including from a remote
# or container build (python3 is already a build dependency).
if(Python3_Interpreter_FOUND)
  set(OM_COVERAGE_PORT 8000 CACHE STRING "Port 'coverage-serve' listens on")
  add_custom_target(coverage-serve
                    COMMAND ${CMAKE_COMMAND} -E echo
                            "Serving the coverage report on http://localhost:${OM_COVERAGE_PORT}/ (Ctrl-C to stop)"
                    COMMAND ${Python3_EXECUTABLE} -m http.server ${OM_COVERAGE_PORT}
                            --directory "${OM_COVERAGE_DIR}"
                    USES_TERMINAL
                    VERBATIM)
endif()
