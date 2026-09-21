// name: type5.mo
// keywords:
// status: incorrect
// suite: disabled
//

type RealInput = input Real;
type RealOutput = output Real;

model A
  RealInput ri;
  input RealOutput ro;
end A;

// Result:
// Error processing file: type5.mo
// [flattening/modelica/scodeinst/type5.mo:9:1-9:30:writable] Notification: From here:
// [flattening/modelica/scodeinst/type5.mo:13:3-13:22:writable] Error: Invalid type prefix 'input' on variable ro, due to existing type prefix 'output'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
