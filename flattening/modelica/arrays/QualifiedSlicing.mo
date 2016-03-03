// name:     QualifiedSlicing
// keywords: array slicing #2532
// status:   correct
//
// Tests that slices are expanded properly when using a qualified cref.
//

model Vector
  Real x[2];
end Vector;

model QualifiedSlicing
  Vector v[2];
equation
  v[:].x[:] = {{sin(time),cos(time)},{sin(time-0.5),cos(time-0.5)}};
end QualifiedSlicing;

// Result:
// class QualifiedSlicing
//   Real v[1].x[1];
//   Real v[1].x[2];
//   Real v[2].x[1];
//   Real v[2].x[2];
// equation
//   v[1].x[1] = sin(time);
//   v[1].x[2] = cos(time);
//   v[2].x[1] = sin(-0.5 + time);
//   v[2].x[2] = cos(-0.5 + time);
// end QualifiedSlicing;
// endResult
