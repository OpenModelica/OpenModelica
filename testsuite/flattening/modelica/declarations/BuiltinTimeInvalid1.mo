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
// [flattening/modelica/declarations/BuiltinTimeInvalid1.mo:10:5-10:25:writable] Error: Built-in variable 'time' may only be used in a model or block.
// [flattening/modelica/declarations/BuiltinTimeInvalid1.mo:13:3-13:15:writable] Error: Class f not found in scope BuiltinTimeInvalid1 (looking for a function or record).
// Error: Error occurred while flattening model BuiltinTimeInvalid1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
