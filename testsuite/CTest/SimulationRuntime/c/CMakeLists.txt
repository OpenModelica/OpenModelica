add_subdirectory(simulation/arrayIndex/unit)
add_subdirectory(simulation/inputXML/read_input_xml)
add_subdirectory(simulation/inputXML/unit)
add_subdirectory(simulation/solver/model_help)
add_subdirectory(util/real_array)
add_subdirectory(util/integer_array)
add_subdirectory(util/boolean_array)
add_subdirectory(util/string_array)
add_subdirectory(runtime/assc)

# Used to build all testsuite dependencies before running ctest
add_custom_target(ctestsuite-depends DEPENDS
  SimulationRuntimeC
  ctestsuite-simulation-arrayIndex-unit
  ctestsuite-simulation-inputXML-read_input_xml
  ctestsuite-simulation-inputXML-unit
  ctestsuite-simulation-solver-model_help
  ctestsuite-util-real_array
  ctestsuite-util-integer_array
  ctestsuite-util-boolean_array
  ctestsuite-util-string_array
  ctestsuite-runtime-assc
)
