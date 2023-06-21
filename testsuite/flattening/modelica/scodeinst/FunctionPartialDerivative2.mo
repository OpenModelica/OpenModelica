// name: FunctionPartialDerivative2
// keywords:
// status: incorrect
// cflags: -d=newInst, --newBackend
//

model FunctionPartialDerivative2
  function f
    input Real x;
    output Real y = x^2;
  end f;

  function df = der(f, y);

  Real y = df(0);
end FunctionPartialDerivative2;

// Result:
// Error processing file: FunctionPartialDerivative2.mo
// [flattening/modelica/scodeinst/FunctionPartialDerivative2.mo:15:3-15:17:writable] Error: 'y' in partial derivative of 'FunctionPartialDerivative2.f' does not name an input parameter of the function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
