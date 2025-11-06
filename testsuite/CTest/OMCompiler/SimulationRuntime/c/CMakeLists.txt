add_subdirectory(arrayIndex/unit)
add_subdirectory(inputXML/unit)

# Used to build all C simulation runtime dependencies before running CTest
add_custom_target(ctestsuite-simulationruntime-c DEPENDS
  omc::simrt::simruntime
  ctestsuite-arrayIndex-unit
  ctestsuite-inputXML-unit
)
