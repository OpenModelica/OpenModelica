// name: type4.mo
// keywords:
// status: incorrect
// suite: disabled
//

type RealInput = input Real;
type RealOutput = output RealInput;

model A
  RealInput ri;
  RealOutput ro;
end A;

// Result:
// Error processing file: type4.mo
// [flattening/modelica/scodeinst/type4.mo:8:1-8:28:writable] Notification: From here:
// [flattening/modelica/scodeinst/type4.mo:9:1-9:35:writable] Error: Invalid type prefix 'output' on class RealInput, due to existing type prefix 'input'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
