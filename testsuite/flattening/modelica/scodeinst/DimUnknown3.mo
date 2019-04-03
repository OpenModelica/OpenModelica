// name: DimUnknown3
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x[:, :];
end A;

model B
  A a[2];
end B;

model DimUnknown3
  B b[4](each a(x = {{{1, 2, 3}, {3, 4, 5}}, {{5, 4, 3}, {3, 2, 1}}}));
end DimUnknown3;

// Result:
// class DimUnknown3
//   Real b[1].a[1].x[1,1];
//   Real b[1].a[1].x[1,2];
//   Real b[1].a[1].x[1,3];
//   Real b[1].a[1].x[2,1];
//   Real b[1].a[1].x[2,2];
//   Real b[1].a[1].x[2,3];
//   Real b[1].a[2].x[1,1];
//   Real b[1].a[2].x[1,2];
//   Real b[1].a[2].x[1,3];
//   Real b[1].a[2].x[2,1];
//   Real b[1].a[2].x[2,2];
//   Real b[1].a[2].x[2,3];
//   Real b[2].a[1].x[1,1];
//   Real b[2].a[1].x[1,2];
//   Real b[2].a[1].x[1,3];
//   Real b[2].a[1].x[2,1];
//   Real b[2].a[1].x[2,2];
//   Real b[2].a[1].x[2,3];
//   Real b[2].a[2].x[1,1];
//   Real b[2].a[2].x[1,2];
//   Real b[2].a[2].x[1,3];
//   Real b[2].a[2].x[2,1];
//   Real b[2].a[2].x[2,2];
//   Real b[2].a[2].x[2,3];
//   Real b[3].a[1].x[1,1];
//   Real b[3].a[1].x[1,2];
//   Real b[3].a[1].x[1,3];
//   Real b[3].a[1].x[2,1];
//   Real b[3].a[1].x[2,2];
//   Real b[3].a[1].x[2,3];
//   Real b[3].a[2].x[1,1];
//   Real b[3].a[2].x[1,2];
//   Real b[3].a[2].x[1,3];
//   Real b[3].a[2].x[2,1];
//   Real b[3].a[2].x[2,2];
//   Real b[3].a[2].x[2,3];
//   Real b[4].a[1].x[1,1];
//   Real b[4].a[1].x[1,2];
//   Real b[4].a[1].x[1,3];
//   Real b[4].a[1].x[2,1];
//   Real b[4].a[1].x[2,2];
//   Real b[4].a[1].x[2,3];
//   Real b[4].a[2].x[1,1];
//   Real b[4].a[2].x[1,2];
//   Real b[4].a[2].x[1,3];
//   Real b[4].a[2].x[2,1];
//   Real b[4].a[2].x[2,2];
//   Real b[4].a[2].x[2,3];
// equation
//   b[1].a[1].x = {{1.0, 2.0, 3.0}, {3.0, 4.0, 5.0}};
//   b[1].a[2].x = {{5.0, 4.0, 3.0}, {3.0, 2.0, 1.0}};
//   b[2].a[1].x = {{1.0, 2.0, 3.0}, {3.0, 4.0, 5.0}};
//   b[2].a[2].x = {{5.0, 4.0, 3.0}, {3.0, 2.0, 1.0}};
//   b[3].a[1].x = {{1.0, 2.0, 3.0}, {3.0, 4.0, 5.0}};
//   b[3].a[2].x = {{5.0, 4.0, 3.0}, {3.0, 2.0, 1.0}};
//   b[4].a[1].x = {{1.0, 2.0, 3.0}, {3.0, 4.0, 5.0}};
//   b[4].a[2].x = {{5.0, 4.0, 3.0}, {3.0, 2.0, 1.0}};
// end DimUnknown3;
// endResult
