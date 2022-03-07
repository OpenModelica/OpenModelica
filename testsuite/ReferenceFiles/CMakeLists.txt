

file(GLOB_RECURSE COMPRESSED_REF_FILES ${CMAKE_CURRENT_SOURCE_DIR}/*.mat.xz)

foreach(compressed_file_path ${COMPRESSED_REF_FILES})
  get_filename_component(compressed_file_dir ${compressed_file_path} DIRECTORY)
  # Remove only the last extension. The file names have a lot of dots.
  get_filename_component(compressed_file_name_no_xz_ext ${compressed_file_path} NAME_WLE)
  set(output_file_path ${compressed_file_dir}/${compressed_file_name_no_xz_ext})

  add_custom_command(
    DEPENDS ${compressed_file_path}
    COMMAND xz --keep --decompress --force ${compressed_file_path}
    OUTPUT ${output_file_path}
    COMMENT "Extracting: ${compressed_file_path}"
  )

  set(OMC_EXTRACTED_REFERENCE_FILES ${OMC_EXTRACTED_REFERENCE_FILES} ${output_file_path})
endforeach()

# A custom target the depends on the extracted files. Makeing sure they get generated when it is
# invoked.
add_custom_target(reference-files
            DEPENDS ${OMC_EXTRACTED_REFERENCE_FILES}
            COMMENT "Extracted reference files to ${CMAKE_CURRENT_SOURCE_DIR}"
        )
