// name: FuncBuiltinTerminal2
// keywords: terminal
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin terminal operator.
//

model FuncBuiltinTerminal2
  parameter Boolean b = terminal();
end FuncBuiltinTerminal2;

// Result:
// Error processing file: FuncBuiltinTerminal2.mo
// [flattening/modelica/scodeinst/FuncBuiltinTerminal2.mo:10:3-10:35:writable] Error: Component b of variability parameter has binding 'terminal()' of higher variability discrete.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
