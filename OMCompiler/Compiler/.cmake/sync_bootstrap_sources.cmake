# Copies a freshly generated set of bootstrapping sources into the working tree
# of the OMBootstrapping submodule (OMCompiler/Compiler/boot/bomc).
#
# Run through cmake -P by the update-bootstrap-sources target, see
# .cmake/bootstrap_sources.cmake. Expects:
#   BOOTSTRAP_C_DIR   directory holding the generated *.c / *.h
#   BOOTSTRAP_HEADER  generated OpenModelicaBootstrappingHeader.h
#   BOMC_DIR          the submodule working tree to update

cmake_minimum_required(VERSION 3.14)

# Part of the snapshot but not generated: hand written external stubs for the
# functions bomc does not link (BackendDAEEXT and friends). Keep them.
set(HAND_WRITTEN_SOURCES FakeBoostrappingExternals.c)

foreach(var BOOTSTRAP_C_DIR BOOTSTRAP_HEADER BOMC_DIR)
  if("${${var}}" STREQUAL "")
    message(FATAL_ERROR "${var} was not passed to sync_bootstrap_sources.cmake.")
  endif()
endforeach()

if(NOT EXISTS ${BOMC_DIR}/.git)
  message(FATAL_ERROR
    "${BOMC_DIR} is not a git checkout. Initialize the submodule first:\n"
    "  git submodule update --init OMCompiler/Compiler/boot/bomc")
endif()

file(GLOB generated_sources ${BOOTSTRAP_C_DIR}/*.c ${BOOTSTRAP_C_DIR}/*.h)
if(NOT generated_sources)
  message(FATAL_ERROR "No generated sources found in ${BOOTSTRAP_C_DIR}.")
endif()
if(NOT EXISTS ${BOOTSTRAP_HEADER})
  message(FATAL_ERROR "${BOOTSTRAP_HEADER} does not exist.")
endif()

set(dest_build_dir ${BOMC_DIR}/bootstrap-sources/build)
set(dest_include_dir ${BOMC_DIR}/tarball-include)
file(MAKE_DIRECTORY ${dest_build_dir})
file(MAKE_DIRECTORY ${dest_include_dir})

set(generated_names "")
foreach(source ${generated_sources})
  get_filename_component(name ${source} NAME)
  list(APPEND generated_names ${name})
endforeach()

# Drop what the compiler no longer generates, otherwise a removed or renamed
# MetaModelica package leaves its C behind and bomc keeps compiling it.
file(GLOB existing_sources ${dest_build_dir}/*.c ${dest_build_dir}/*.h)
set(removed_count 0)
foreach(source ${existing_sources})
  get_filename_component(name ${source} NAME)
  if(NOT name IN_LIST generated_names AND NOT name IN_LIST HAND_WRITTEN_SOURCES)
    message(STATUS "Removing stale ${name}")
    file(REMOVE ${source})
    math(EXPR removed_count "${removed_count} + 1")
  endif()
endforeach()

file(COPY ${generated_sources} DESTINATION ${dest_build_dir})
file(COPY ${BOOTSTRAP_HEADER} DESTINATION ${dest_include_dir})

list(LENGTH generated_sources copied_count)
message(STATUS "Copied ${copied_count} files to ${dest_build_dir} (removed ${removed_count} stale).")
message(STATUS "")
message(STATUS "Note: bootstrap-sources/Makefile.sources is left untouched. It only feeds the")
message(STATUS "autotools bootstrap-from-tarball, which is on its way out; the CMake build of")
message(STATUS "bomc globs bootstrap-sources/build/*.c and does not read it.")
message(STATUS "")
message(STATUS "Next steps:")
message(STATUS "  1. Commit the changes in ${BOMC_DIR} and open a PR against OMBootstrapping.")
message(STATUS "  2. Re-run cmake and rebuild to check that bomc builds from the new sources.")
message(STATUS "  3. Point the submodule at the merged commit in a PR against OpenModelica.")
