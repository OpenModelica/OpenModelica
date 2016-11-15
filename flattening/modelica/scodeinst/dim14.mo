// name: dim14.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model A
  Real x[:, :];
end A;

model B
  A a[2];
end B;

model C
  B b[4](each a(x = {{{1, 2, 3}, {3, 4, 5}}, {{5, 4, 3}, {3, 2, 1}}}));
end C;

// Result:
// class C
//   Real b[1].a[1].x[1,1] = 1.0;
//   Real b[1].a[1].x[1,2] = 2.0;
//   Real b[1].a[1].x[1,3] = 3.0;
//   Real b[1].a[1].x[2,1] = 3.0;
//   Real b[1].a[1].x[2,2] = 4.0;
//   Real b[1].a[1].x[2,3] = 5.0;
//   Real b[1].a[2].x[1,1] = 5.0;
//   Real b[1].a[2].x[1,2] = 4.0;
//   Real b[1].a[2].x[1,3] = 3.0;
//   Real b[1].a[2].x[2,1] = 3.0;
//   Real b[1].a[2].x[2,2] = 2.0;
//   Real b[1].a[2].x[2,3] = 1.0;
//   Real b[2].a[1].x[1,1] = 1.0;
//   Real b[2].a[1].x[1,2] = 2.0;
//   Real b[2].a[1].x[1,3] = 3.0;
//   Real b[2].a[1].x[2,1] = 3.0;
//   Real b[2].a[1].x[2,2] = 4.0;
//   Real b[2].a[1].x[2,3] = 5.0;
//   Real b[2].a[2].x[1,1] = 5.0;
//   Real b[2].a[2].x[1,2] = 4.0;
//   Real b[2].a[2].x[1,3] = 3.0;
//   Real b[2].a[2].x[2,1] = 3.0;
//   Real b[2].a[2].x[2,2] = 2.0;
//   Real b[2].a[2].x[2,3] = 1.0;
//   Real b[3].a[1].x[1,1] = 1.0;
//   Real b[3].a[1].x[1,2] = 2.0;
//   Real b[3].a[1].x[1,3] = 3.0;
//   Real b[3].a[1].x[2,1] = 3.0;
//   Real b[3].a[1].x[2,2] = 4.0;
//   Real b[3].a[1].x[2,3] = 5.0;
//   Real b[3].a[2].x[1,1] = 5.0;
//   Real b[3].a[2].x[1,2] = 4.0;
//   Real b[3].a[2].x[1,3] = 3.0;
//   Real b[3].a[2].x[2,1] = 3.0;
//   Real b[3].a[2].x[2,2] = 2.0;
//   Real b[3].a[2].x[2,3] = 1.0;
//   Real b[4].a[1].x[1,1] = 1.0;
//   Real b[4].a[1].x[1,2] = 2.0;
//   Real b[4].a[1].x[1,3] = 3.0;
//   Real b[4].a[1].x[2,1] = 3.0;
//   Real b[4].a[1].x[2,2] = 4.0;
//   Real b[4].a[1].x[2,3] = 5.0;
//   Real b[4].a[2].x[1,1] = 5.0;
//   Real b[4].a[2].x[1,2] = 4.0;
//   Real b[4].a[2].x[1,3] = 3.0;
//   Real b[4].a[2].x[2,1] = 3.0;
//   Real b[4].a[2].x[2,2] = 2.0;
//   Real b[4].a[2].x[2,3] = 1.0;
// end C;
// endResult
