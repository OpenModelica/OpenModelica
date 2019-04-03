// name:     ReinitInvalidType3
// keywords: reinit
// status:   incorrect
//
// Tests that the compiler checks that the first argument to reinit is a variable.
//

model ReinitInvalidType3
  constant Real x=0.1;
equation
  when time > 1 then
    reinit(x, 2*x);
  end when;
end ReinitInvalidType3;

// Result:
// Error processing file: ReinitInvalidType3.mo
// [flattening/modelica/operators/ReinitInvalidType3.mo:12:5-12:19:writable] Error: The first argument to reinit must be a continuous time variable, but x is constant.
// Error: Error occurred while flattening model ReinitInvalidType3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
