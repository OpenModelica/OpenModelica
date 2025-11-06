
# Include subdirectories
add_subdirectory(OMCompiler/SimulationRuntime/c)

# Used to build all testsuite dependencies before running unit tests
add_custom_target(ctestsuite-depends DEPENDS
  ctestsuite-simulationruntime-c
)
