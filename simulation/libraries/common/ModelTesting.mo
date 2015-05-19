package OpenModelicaModelTesting

type Kind = enumeration(Instantiation "Like instantiateModel()",
                        Translation "Like translateModel",
                        Compilation "Like buildModel",
                        SuppressedSimulation "Like simulate(), but suppresses output (only checks exit status)",
                        SimpleSimulation "Like simulate()",
                        SuppressedVerifiedSimulation "Like simulate(), but suppresses output (only checks exit status), and also verifies the simulation results",
                        VerifiedSimulation "Like simulate(), but also verifies the results against a known good source");

type SimulationRuntime = enumeration(C "C Runtime",
                                     Cpp "Cpp Runtime");

type DiffAlgorithm = enumeration(compareSimulationResults, diffSimulationResults);

end OpenModelicaModelTesting;
