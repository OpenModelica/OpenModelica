// name: End3
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function last
  input Real x[:];
  output Real y;
algorithm
  y := x[end];
end last;

model End3
  Real x[3] = {1, 2, 3};
  Real y = last(x);
end End3;


// Result:
// function last
//   input Real[:] x;
//   output Real y;
// algorithm
//   y := x[size(x, 1)];
// end last;
//
// class End3
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y = last(x);
// equation
//   x = {1.0, 2.0, 3.0};
// end End3;
// endResult
