// name: InvalidVariability2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidVariability2
  connector C = Real;

  C c1;
  parameter C c2;
equation
  connect(c2, c1);
end InvalidVariability2;

// Result:
// Error processing file: InvalidVariability2.mo
// [flattening/modelica/scodeinst/InvalidVariability2.mo:13:3-13:18:writable] Error: Cannot connect parameter c2 to non-constant/parameter c1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
