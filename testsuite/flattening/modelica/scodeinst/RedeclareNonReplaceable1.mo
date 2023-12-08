// name: RedeclareNonReplaceable1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  Real x = 1;
end A;

model B
  extends A;
  Real y = 3;
end B;

model C
  A a;
end C;

model RedeclareNonReplaceable1
  extends C(redeclare B a);
end RedeclareNonReplaceable1;

// Result:
// Error processing file: RedeclareNonReplaceable1.mo
// [flattening/modelica/scodeinst/RedeclareNonReplaceable1.mo:21:13-21:26:writable] Error: Redeclaration with a new type requires 'a' to be replaceable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
