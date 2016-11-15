// name: PartialInst
// keywords: partial
// status: incorrect
// cflags:   -d=newInst
//
// Checks that it's not possible to instantiate a partial class.
//

partial model A
  Real x;
end A;

model PartialInst
  A a;
end PartialInst;

// Result:
// Error processing file: PartialInst.mo
// [flattening/modelica/scodeinst/PartialInst.mo:14:3-14:6:writable] Error: Illegal to instantiate partial class A.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
