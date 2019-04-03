// name: ReinitInvalid6
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ReinitInvalid6
  Real x;
equation
  reinit(x, 2.0);
end ReinitInvalid6;

// Result:
// Error processing file: ReinitInvalid6.mo
// [flattening/modelica/scodeinst/ReinitInvalid6.mo:10:3-10:17:writable] Error: Operator reinit may only be used in the body of a when equation.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
