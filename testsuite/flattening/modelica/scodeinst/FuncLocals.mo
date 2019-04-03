// name: FuncLocals
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that functions can have local parameters.
//

function f
  input Real x;
  output Real y;
protected
  parameter Real z = 2.0;
algorithm
  y := x * z;
end f;

model FuncLocals
  Real x = f(4.0);
end FuncLocals;

// Result:
// class FuncLocals
//   Real x = 8.0;
// end FuncLocals;
// endResult
