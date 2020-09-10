

# Macro for adding a corba target. Takes a corba source file, e.g. my_source.idl,
# and generates my_source.cc and my_source.h in the specified output directory.
#
# Usage:
#   omc_add_omniorb_corba_target(${idl_compiler} ${corba_source_file} ${output_directory})
#
# Inputs:
#   idl_compiler: The idl compiler to be used.
#   corba_source_file: Full path to the corba source file.
#   output_directory: A directory where the outputs should be generated. It is
#                     recommended to make this a directory in the build folder
#                     instead of the source folder.

macro(omc_add_omniorb_corba_target idl_compiler corba_source_file output_directory)

    get_filename_component(file_name_no_ext ${corba_source_file} NAME_WLE)

    add_custom_command(
        DEPENDS ${corba_source_file}
        COMMAND ${idl_compiler} -T -bcxx -Wbh=.h -Wbs=.cc -p../../lib/python -Wbdebug
                    -C${output_directory} ${corba_source_file}
        OUTPUT ${output_directory}/${file_name_no_ext}.cc ${output_directory}/${file_name_no_ext}.h
        COMMENT "Generating ${file_name_no_ext}.cc ${file_name_no_ext}.h from ${corba_source_file}"
    )

    set_source_files_properties(${output_directory}/${file_name_no_ext}.cc GENERATED)
    set_source_files_properties(${output_directory}/${file_name_no_ext}.h GENERATED)


endmacro(omc_add_omniorb_corba_target)

