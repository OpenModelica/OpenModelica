// name:     QualifiedEnd
// keywords: array, end, #3250
// status:   correct
//
// Tests the usage of end as subscript of a qualified or fully qualified cref.
//

model A
  Real x[3];
end A;

package P
  constant Real x[2] = {1, 2};
end P;

model QualifiedEnd
  A a[2];
  Real x1[:] = a[end].x[1:end];
  Real x2[:] = .P.x[1:end];
end QualifiedEnd;

// Result:
// class QualifiedEnd
//   Real a[1].x[1];
//   Real a[1].x[2];
//   Real a[1].x[3];
//   Real a[2].x[1];
//   Real a[2].x[2];
//   Real a[2].x[3];
//   Real x1[1];
//   Real x1[2];
//   Real x1[3];
//   Real x2[1];
//   Real x2[2];
// equation
//   x1 = {a[2].x[1], a[2].x[2], a[2].x[3]};
//   x2 = {1.0, 2.0};
// end QualifiedEnd;
// endResult
