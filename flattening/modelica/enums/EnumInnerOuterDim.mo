// name:     EnumInnerOuterDim
// keywords: enumeration enum inner outer dimension
// status:   correct
//
// Tests that inner outer arrays with enumeration dimensions are handled
// correctly.
//

type E = enumeration (A, B, C);

block Model1
  outer parameter Real[E] p1;
  parameter Real[E] p2 = p1;
end Model1;

block Model2
  inner parameter Real[E] p1;
  Model1 m1;
end Model2;

// Result:
// class Model2
//   parameter Real p1[E.A];
//   parameter Real p1[E.B];
//   parameter Real p1[E.C];
//   parameter Real m1.p2[E.A] = p1[E.A];
//   parameter Real m1.p2[E.B] = p1[E.B];
//   parameter Real m1.p2[E.C] = p1[E.C];
// end Model2;
// endResult
