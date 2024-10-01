// name: FunctionPartialDerivative3
// keywords:
// status: incorrect
//

model FunctionPartialDerivative3
  function f
    input Integer x;
    output Real y = x^2;
  end f;

  function df = der(f, x);

  Real y = df(0);
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end FunctionPartialDerivative3;

// Result:
// Error processing file: FunctionPartialDerivative3.mo
// [flattening/modelica/scodeinst/FunctionPartialDerivative3.mo:12:3-12:26:writable] Error: 'x' in partial derivative of 'FunctionPartialDerivative3.f' is not a scalar Real input parameter of the function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
