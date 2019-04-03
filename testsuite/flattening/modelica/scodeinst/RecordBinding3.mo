// name: RecordBinding3
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x[:] = {1, 2, 3};
  Real y[:];
  Real z[size(y, 1)];
end R;

model RecordBinding3
  R r = R(ones(5), {1, 2}, {3, 4});
end RecordBinding3;

// Result:
// class RecordBinding3
//   Real r.x[1];
//   Real r.x[2];
//   Real r.x[3];
//   Real r.x[4];
//   Real r.x[5];
//   Real r.y[1];
//   Real r.y[2];
//   Real r.z[1];
//   Real r.z[2];
// equation
//   r.x = {1.0, 1.0, 1.0, 1.0, 1.0};
//   r.y = {1.0, 2.0};
//   r.z = {3.0, 4.0};
// end RecordBinding3;
// endResult
