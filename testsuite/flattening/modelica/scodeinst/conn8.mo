// name: conn8.mo
// keywords:
// status: incorrect
// suite: disabled
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
// [flattening/modelica/scodeinst/conn8.mo:8:1-8:25:writable] Notification: From here:
// [flattening/modelica/scodeinst/conn8.mo:12:3-12:14:writable] Error: Invalid type prefix 'output' on variable c3, due to existing type prefix 'input'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
