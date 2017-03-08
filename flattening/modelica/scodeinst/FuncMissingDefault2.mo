// name: FuncMissingDefault2
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that a warning is given when a parameter that doesn't have a default
// argument is after a parameter that does.
// 

function f
  input Real x;
  input Real y = 1.0;
  input Real z;
  output Real w = x + y + z;
end f;

model M
  Real x = f(1.0, 2.0, 3.0);
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
// end M;
// [flattening/modelica/scodeinst/FuncMissingDefault2.mo:13:3-13:15:writable] Warning: Missing default argument on function parameter z.
//
// endResult
