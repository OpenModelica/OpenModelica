// name: conn8.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

connector C = input Real;

model A
  C c1, c2;
  output C c3;
equation
  connect(c1, c2);
end A;
// Result:
// Error processing file: conn8.mo
// [flattening/modelica/scodeinst/conn8.mo:7:1-7:25:writable] Notification: From here:
// [flattening/modelica/scodeinst/conn8.mo:11:3-11:14:writable] Error: Invalid type prefix 'output' on variable c3, due to existing type prefix 'input'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
