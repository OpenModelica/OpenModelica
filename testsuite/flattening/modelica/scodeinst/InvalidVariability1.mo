// name: InvalidVariability1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidVariability1
  connector C = Real;

  C c1;
  parameter C c2;
equation
  connect(c1, c2);
end InvalidVariability1;

// Result:
// Error processing file: InvalidVariability1.mo
// [flattening/modelica/scodeinst/InvalidVariability1.mo:13:3-13:18:writable] Error: Cannot connect parameter c2 to non-constant/parameter c1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
