// name: ArrayEquation1
// keywords:
// status: correct
// cflags: -d=newInst
//

model ArrayEquation1
  parameter Integer N = 2;
  Real x[N, N];
  Real y[:, :] = transpose(x)*x;
end ArrayEquation1;

// Result:
// class ArrayEquation1
//   final parameter Integer N = 2;
//   Real x[1,1];
//   Real x[1,2];
//   Real x[2,1];
//   Real x[2,2];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[2,1];
//   Real y[2,2];
// equation
//   y = {{x[1,1] * x[1,1] + x[2,1] * x[2,1], x[1,1] * x[1,2] + x[2,1] * x[2,2]}, {x[1,2] * x[1,1] + x[2,2] * x[2,1], x[1,2] * x[1,2] + x[2,2] * x[2,2]}};
// end ArrayEquation1;
// endResult
