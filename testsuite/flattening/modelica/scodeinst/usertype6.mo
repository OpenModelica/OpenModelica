// name: usertype6.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//

type MyReal
  extends Real;
  Real y;
end MyReal;

model M
  MyReal x;
end M;

// Result:
// Error processing file: usertype6.mo
// [flattening/modelica/scodeinst/usertype6.mo:7:1-10:11:writable] Error: A class extending from builtin type Real may not have other elements.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
