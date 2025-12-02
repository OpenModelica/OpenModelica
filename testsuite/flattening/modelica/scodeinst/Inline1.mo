// name: Inline1
// keywords:
// status: correct
//

model A
  input Real x[3];
  input Real y[3];
  output Real z[3];
equation
  z = cross(x, y);
end A;

model Inline1
  A a[1];
equation
  a[1].x = time * {1, 2, 3};
  a[1].y = {time, time^3, time^2};
end Inline1;

// Result:
// class Inline1
//   Real a[1].x[1];
//   Real a[1].x[2];
//   Real a[1].x[3];
//   Real a[1].y[1];
//   Real a[1].y[2];
//   Real a[1].y[3];
//   Real a[1].z[1];
//   Real a[1].z[2];
//   Real a[1].z[3];
// equation
//   a[1].z[1] = a[1].x[2] * a[1].y[3] - a[1].x[3] * a[1].y[2];
//   a[1].z[2] = a[1].x[3] * a[1].y[1] - a[1].x[1] * a[1].y[3];
//   a[1].z[3] = a[1].x[1] * a[1].y[2] - a[1].x[2] * a[1].y[1];
//   a[1].x[1] = time;
//   a[1].x[2] = time * 2.0;
//   a[1].x[3] = time * 3.0;
//   a[1].y[1] = time;
//   a[1].y[2] = time ^ 3.0;
//   a[1].y[3] = time ^ 2.0;
// end Inline1;
// endResult
