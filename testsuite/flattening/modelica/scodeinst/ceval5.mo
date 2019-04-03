// name: ceval5.mo
// status: incorrect
// cflags: -d=newInst

model A
  parameter Real n = 3;
  parameter Integer m = n;
  Real x[m] = {1.0, 1.0, 1.0}; //fill(1.0, m);
end A;

// Result:
// Error processing file: ceval5.mo
// [flattening/modelica/scodeinst/ceval5.mo:7:3-7:26:writable] Error: Type mismatch in binding m = n, expected subtype of Integer, got type Real.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
