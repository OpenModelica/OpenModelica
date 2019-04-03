// name: ReinitInvalid3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ReinitInvalid3
  constant Real x=0.1;
equation
  when time > 1 then
    reinit(x, 2*x);
  end when;
end ReinitInvalid3;

// Result:
// Error processing file: ReinitInvalid3.mo
// [flattening/modelica/scodeinst/ReinitInvalid3.mo:11:5-11:19:writable] Error: The first argument to reinit must be a continuous time variable, but x is constant.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
