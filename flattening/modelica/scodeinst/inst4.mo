// name: inst4.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
//


type B
  Real x;
end B;

class MyReal
  extends Real;
  extends B;
end MyReal;

model A
  MyReal r;
end A;

// Result:
// Error processing file: inst4.mo
// [flattening/modelica/scodeinst/inst4.mo:13:1-16:11:writable] Error: A class extending from builtin type Real may not have other elements.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
