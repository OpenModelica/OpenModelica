// name: ReinitInvalid2
// keywords:
// status: incorrect
//

model ReinitInvalid2
  parameter Real x = 0.1;
equation
  when time > 1 then
    reinit(x, 2*x);
  end when;
end ReinitInvalid2;

// Result:
// Error processing file: ReinitInvalid2.mo
// [flattening/modelica/scodeinst/ReinitInvalid2.mo:10:5-10:19:writable] Error: The first argument to reinit must be a continuous time variable, but x is parameter.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
