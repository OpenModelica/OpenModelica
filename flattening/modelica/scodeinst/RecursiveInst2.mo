// name: RecursiveInst2
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model A
  RecursiveInst2 r;
end A;

model RecursiveInst2
  A a;
end RecursiveInst2;

// Result:
// Error processing file: RecursiveInst2.mo
// [flattening/modelica/scodeinst/RecursiveInst2.mo:9:3-9:19:writable] Error: Declaration of element r causes recursive definition of class A.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
