# Mirror the hand-written Rust sources (MANIFEST, relative to SRC) into the
# per-build copy DST, so concurrent builds don't share one in-source tree.
# file(COPY) preserves timestamps and skips up-to-date files. The transpile
# regenerates every other *.rs into DST; only committed inputs are listed (read
# as a plain file, not git, so tarball builds work).
#   cmake -DSRC=<src> -DDST=<dst> -DMANIFEST=<file> -P rust_src_sync.cmake

if(NOT SRC OR NOT DST OR NOT MANIFEST)
  message(FATAL_ERROR "rust_src_sync: SRC, DST and MANIFEST must all be set.")
endif()

file(STRINGS ${MANIFEST} _lines)
foreach(_rel ${_lines})
  string(STRIP "${_rel}" _rel)
  if(_rel STREQUAL "" OR _rel MATCHES "^#")
    continue()
  endif()
  if(NOT EXISTS ${SRC}/${_rel})
    message(FATAL_ERROR "rust_src_sync: listed source missing: ${SRC}/${_rel}")
  endif()
  get_filename_component(_dir ${_rel} DIRECTORY)
  file(COPY ${SRC}/${_rel} DESTINATION ${DST}/${_dir})
endforeach()

# Builtin .mo that openmodelica_vfs include_str!s via ../../../{FrontEnd,NFFrontEnd}
# (paths reaching past the crate tree into Compiler/); mirror them beside the copy
# at the same relative depth. Keep in sync with openmodelica_vfs/src/lib.rs.
get_filename_component(_src_parent ${SRC} DIRECTORY)
get_filename_component(_dst_parent ${DST} DIRECTORY)
foreach(_rel
    FrontEnd/ModelicaBuiltin.mo FrontEnd/MetaModelicaBuiltin.mo
    FrontEnd/AnnotationsBuiltin_1_x.mo FrontEnd/AnnotationsBuiltin_2_x.mo
    FrontEnd/AnnotationsBuiltin_3_x.mo NFFrontEnd/NFModelicaBuiltin.mo)
  get_filename_component(_dir ${_rel} DIRECTORY)
  file(COPY ${_src_parent}/${_rel} DESTINATION ${_dst_parent}/${_dir})
endforeach()
