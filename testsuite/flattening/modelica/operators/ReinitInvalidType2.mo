// name:     ReinitInvalidType2
// keywords: reinit
// status:   incorrect
//
// Tests that the compiler checks that the first argument to reinit is a variable.
//

model ReinitInvalidType2
  parameter Real x=0.1;
equation
  when time > 1 then
    reinit(x, 2*x);
  end when;
end ReinitInvalidType2;

// Result:
// Error processing file: ReinitInvalidType2.mo
// [flattening/modelica/operators/ReinitInvalidType2.mo:12:5-12:19:writable] Error: The first argument to reinit must be a continuous time variable, but x is parameter.
// Error: Error occurred while flattening model ReinitInvalidType2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
