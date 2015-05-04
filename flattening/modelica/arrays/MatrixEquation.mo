// status: correct
// #2521

model Vector
  Real x[2];
end Vector;

model MatrixEquation
  Vector v[2];
equation
  v.x = {{1,2},{3,cos(time)}};
end MatrixEquation;

// Result:
// class MatrixEquation
//   Real v[1].x[1];
//   Real v[1].x[2];
//   Real v[2].x[1];
//   Real v[2].x[2];
// equation
//   v[1].x[1] = 1.0;
//   v[1].x[2] = 2.0;
//   v[2].x[1] = 3.0;
//   v[2].x[2] = cos(time);
// end MatrixEquation;
// endResult
