// name: SimulateFlag1
// keywords:
// status: correct
// cflags: -u
//
// Tests the -u flag for simulating a model.
//

model M
  Real x = time;
  annotation(experiment(StopTime = 2.0));
end M;

// Result:
// record SimulationResult
//     resultFile = "M_res.mat",
//     simulationOptions = "startTime = 0.0, stopTime = 2.0, numberOfIntervals = 500, tolerance = 1e-6, method = 'dassl', fileNamePrefix = 'M', options = '', outputFormat = 'mat', variableFilter = '.*', cflags = '', simflags = ''",
//     messages = "LOG_SUCCESS       | info    | The initialization finished successfully without homotopy method.
// LOG_SUCCESS       | info    | The simulation finished successfully.
// "
// end SimulationResult;
// endResult
