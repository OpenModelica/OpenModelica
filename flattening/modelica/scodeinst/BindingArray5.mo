// name: BindingArray5
// keywords:
// status: correct
// cflags: -d=newInst
//

type MyReal = Real[4];

model A
  Real x(start = 1.0);
  Real y[2];
  MyReal z;
end A;

model B
  A[3] a;
  A b[3](x = {7, 8, 9});
end B;

model BindingArray5
  B b[2](a.x = {{1, 2, 3}, {4, 5, 6}});
end BindingArray5;

// Result:
// class BindingArray5
//   Real b[1].a[1].x(start = 1.0) = 1.0;
//   Real b[1].a[1].y[1];
//   Real b[1].a[1].y[2];
//   Real b[1].a[1].z[1];
//   Real b[1].a[1].z[2];
//   Real b[1].a[1].z[3];
//   Real b[1].a[1].z[4];
//   Real b[1].a[2].x(start = 1.0) = 2.0;
//   Real b[1].a[2].y[1];
//   Real b[1].a[2].y[2];
//   Real b[1].a[2].z[1];
//   Real b[1].a[2].z[2];
//   Real b[1].a[2].z[3];
//   Real b[1].a[2].z[4];
//   Real b[1].a[3].x(start = 1.0) = 3.0;
//   Real b[1].a[3].y[1];
//   Real b[1].a[3].y[2];
//   Real b[1].a[3].z[1];
//   Real b[1].a[3].z[2];
//   Real b[1].a[3].z[3];
//   Real b[1].a[3].z[4];
//   Real b[1].b[1].x(start = 1.0) = 7.0;
//   Real b[1].b[1].y[1];
//   Real b[1].b[1].y[2];
//   Real b[1].b[1].z[1];
//   Real b[1].b[1].z[2];
//   Real b[1].b[1].z[3];
//   Real b[1].b[1].z[4];
//   Real b[1].b[2].x(start = 1.0) = 8.0;
//   Real b[1].b[2].y[1];
//   Real b[1].b[2].y[2];
//   Real b[1].b[2].z[1];
//   Real b[1].b[2].z[2];
//   Real b[1].b[2].z[3];
//   Real b[1].b[2].z[4];
//   Real b[1].b[3].x(start = 1.0) = 9.0;
//   Real b[1].b[3].y[1];
//   Real b[1].b[3].y[2];
//   Real b[1].b[3].z[1];
//   Real b[1].b[3].z[2];
//   Real b[1].b[3].z[3];
//   Real b[1].b[3].z[4];
//   Real b[2].a[1].x(start = 1.0) = 4.0;
//   Real b[2].a[1].y[1];
//   Real b[2].a[1].y[2];
//   Real b[2].a[1].z[1];
//   Real b[2].a[1].z[2];
//   Real b[2].a[1].z[3];
//   Real b[2].a[1].z[4];
//   Real b[2].a[2].x(start = 1.0) = 5.0;
//   Real b[2].a[2].y[1];
//   Real b[2].a[2].y[2];
//   Real b[2].a[2].z[1];
//   Real b[2].a[2].z[2];
//   Real b[2].a[2].z[3];
//   Real b[2].a[2].z[4];
//   Real b[2].a[3].x(start = 1.0) = 6.0;
//   Real b[2].a[3].y[1];
//   Real b[2].a[3].y[2];
//   Real b[2].a[3].z[1];
//   Real b[2].a[3].z[2];
//   Real b[2].a[3].z[3];
//   Real b[2].a[3].z[4];
//   Real b[2].b[1].x(start = 1.0) = 7.0;
//   Real b[2].b[1].y[1];
//   Real b[2].b[1].y[2];
//   Real b[2].b[1].z[1];
//   Real b[2].b[1].z[2];
//   Real b[2].b[1].z[3];
//   Real b[2].b[1].z[4];
//   Real b[2].b[2].x(start = 1.0) = 8.0;
//   Real b[2].b[2].y[1];
//   Real b[2].b[2].y[2];
//   Real b[2].b[2].z[1];
//   Real b[2].b[2].z[2];
//   Real b[2].b[2].z[3];
//   Real b[2].b[2].z[4];
//   Real b[2].b[3].x(start = 1.0) = 9.0;
//   Real b[2].b[3].y[1];
//   Real b[2].b[3].y[2];
//   Real b[2].b[3].z[1];
//   Real b[2].b[3].z[2];
//   Real b[2].b[3].z[3];
//   Real b[2].b[3].z[4];
// end BindingArray5;
// endResult
