add_subdirectory(arrayIndex/unit)
add_subdirectory(inputXML/read_input_xml)
add_subdirectory(inputXML/unit)

# Used to build all testsuite dependencies before running ctest
add_custom_target(ctestsuite-depends DEPENDS
  SimulationRuntimeC
  ctestsuite-arrayIndex-unit
  ctestsuite-inputXML-read_input_xml
  ctestsuite-inputXML-unit
)
