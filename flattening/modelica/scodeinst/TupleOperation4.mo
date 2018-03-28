// name: TupleOperation4
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  input Real t;
  output Integer n1 = 2;
  output Integer n2 = 3;
end f;

model TupleOperation4
  Real x[3];
  Real y;
equation
  y = x[f(time)];
end TupleOperation4;

// Result:
// function f
//   input Real t;
//   output Integer n1 = 2;
//   output Integer n2 = 3;
// end f;
//
// class TupleOperation4
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y;
// equation
//   y = x[f(time)[1]];
// end TupleOperation4;
// endResult
