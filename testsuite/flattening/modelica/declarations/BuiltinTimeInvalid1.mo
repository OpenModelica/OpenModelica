// name:     BuiltinTimeInvalid1
// keywords: time builtin
// status:   incorrect
//
// Checks that time is not allowed in functions.
//

model BuiltinTimeInvalid1
  function f
    output Real x = time;
  end f;

  Real x = f();
end BuiltinTimeInvalid1;

// Result:
// Error processing file: BuiltinTimeInvalid1.mo
// [flattening/modelica/declarations/BuiltinTimeInvalid1.mo:10:5-10:25:writable] Error: time is not allowed in a function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
