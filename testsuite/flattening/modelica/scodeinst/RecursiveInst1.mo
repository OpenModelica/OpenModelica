// name: RecursiveInst1
// keywords:
// status: incorrect
//
//

model RecursiveInst1
  RecursiveInst1 c;
end RecursiveInst1;

// Result:
// Error processing file: RecursiveInst1.mo
// [flattening/modelica/scodeinst/RecursiveInst1.mo:8:3-8:19:writable] Error: Declaration of element c causes recursive definition of class RecursiveInst1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
