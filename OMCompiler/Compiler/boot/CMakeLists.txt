cmake_minimum_required(VERSION 3.14)
project(bomc)


file(GLOB BOOTSTRAP_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/bootstrap-sources/build/*.c)

add_executable(bomc)
target_sources(bomc PRIVATE ${BOOTSTRAP_SOURCES})
target_sources(bomc PRIVATE ../.cmake/omc_main.c)


# There is a lonely omc_file.h in Util/. It belongs in runtime/. Remove this when it is moved.
target_include_directories(bomc PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../Util)

target_link_libraries(bomc PRIVATE omc::parser-boot)
target_link_libraries(bomc PRIVATE omc::compiler::runtime-boot)
target_link_libraries(bomc PRIVATE omc::compiler::graphstream-boot)
# target_link_libraries(bomc PRIVATE omc::simrt::runtime)
target_link_libraries(bomc PRIVATE omc::3rd::modelica_external_c)
target_link_libraries(bomc PRIVATE omc::3rd::modelica_io)


target_compile_definitions(bomc PRIVATE ADD_METARECORD_DEFINITIONS=)



set_target_properties(bomc
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin
)

add_custom_command (
    TARGET bomc
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/../FrontEnd/ModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/lib/omc/ModelicaBuiltin.mo
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/../FrontEnd/MetaModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/lib/omc/MetaModelicaBuiltin.mo
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/../NFFrontEnd/NFModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/lib/omc/NFModelicaBuiltin.mo
    COMMENT "Copying (NF/Meta/Modelica)Builtin.mo files for the bootstrapped omc.")

