add_subdirectory(arrayIndex/unit)
add_subdirectory(inputXML/unit)

# Used to build all testsuite dependencies before running ctest
add_custom_target(ctestsuite-depends DEPENDS
  SimulationRuntimeC
  ctestsuite-arrayIndex-unit
  ctestsuite-inputXML-unit
)
