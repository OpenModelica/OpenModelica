// name: FuncMissingDefault2
// keywords:
// status: correct
// cflags: -d=newInst
//
// This is actaully valid (no warning needed). e.g. a call like this should work f(1.0, z=2.0)
// // Checks that a warning is given when a parameter that doesn't have a default
// // argument is after a parameter that does.
// 

function f
  input Real x;
  input Real y = 1.0;
  input Real z; // No warning needed
  output Real w = x + y + z;
end f;

model M
  Real x = f(1.0, 2.0, 3.0);
  Real y = f(1.0, z=2.0);
end M;

// Result:
// function f
//   input Real x;
//   input Real y = 1.0;
//   input Real z;
//   output Real w = x + y + z;
// end f;
//
// class M
//   Real x = f(1.0, 2.0, 3.0);
//   Real y = f(1.0, 1.0, 2.0);
// end M;
// endResult
