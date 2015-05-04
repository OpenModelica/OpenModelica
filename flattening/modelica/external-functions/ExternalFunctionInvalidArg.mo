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
// [flattening/modelica/external-functions/ExternalFunctionInvalidArg.mo:18:3-18:19:writable] Error: Class f not found in scope ExternalFunctionInvalidArg (looking for a function or record).
// Error: Error occurred while flattening model ExternalFunctionInvalidArg
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
