// name:   ExternalFunctionInvalidArg
// keywords: external function
// status: incorrect
//
// Checks that expressions such as arrays are not allowed as external function
// arguments.
//

model ExternalFunctionInvalidArg
  record R
    Real x;
  end R;
  function f
    input R x;
    output R y;
  external "C" f(x, y, {1, 2, 3});
  end f;
  R r = f(R(time));
end ExternalFunctionInvalidArg;

// Result:
// Error processing file: ExternalFunctionInvalidArg.mo
// [flattening/modelica/external-functions/ExternalFunctionInvalidArg.mo:13:3-17:8:writable] Error: Expression {1, 2, 3} cannot be an external argument. Only identifiers, scalar constants, and size-expressions are allowed.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
