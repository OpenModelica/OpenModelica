// name: FuncBuiltinPrevious3
// keywords: pre
// status: correct
// cflags: -d=newInst
//
// Tests the builtin previous operator.
//

function f
  input Real x[3];
  output Real y[3] = x;
end f;

model FuncBuiltinPrevious3
  Real x[3];
equation
  x = f(previous(x));
end FuncBuiltinPrevious3;

// Result:
// function f
//   input Real[3] x;
//   output Real[3] y = x;
// end f;
//
// class FuncBuiltinPrevious3
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = f(array(previous(x[$i1]) for $i1 in 1:3));
// end FuncBuiltinPrevious3;
// endResult
