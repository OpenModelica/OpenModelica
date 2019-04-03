// name: ReinitInvalid4
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ReinitInvalid4
  Real x = 0.1;
equation
  when time > 1 then
    reinit(x, {1.0, 2.0, 3.0});
  end when;
end ReinitInvalid4;

// Result:
// Error processing file: ReinitInvalid4.mo
// [flattening/modelica/scodeinst/ReinitInvalid4.mo:11:5-11:31:writable] Error: Type mismatch for positional argument 2 in reinit(={1.0, 2.0, 3.0}). The argument has type:
//   Real[3]
// expected type:
//   Real
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
