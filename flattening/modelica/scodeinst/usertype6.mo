// name: usertype6.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model MyReal
  extends Real;
  Real y;
end MyReal;

model M
  MyReal x;
end M;

// Result:
// Error processing file: usertype6.mo
// [flattening/modelica/scodeinst/usertype6.mo:8:3-8:15:writable] Error: A class extending from builtin type Real may not have other elements.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
