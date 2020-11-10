// name:     ArrayConstruct1
// keywords: <insert keywords here>
// status:   correct
//
// Drmodelica: 7.2  Array Constructor (p. 210)
// cflags: -d=-newInst
//

type Angle = Real(unit="rad"); // The type Angle is a subtype of Real

class ArrayConstruct1
  Integer[3] a = {1, 2, 3}; // A 3-vector of type Integer[3]
  Real[3] b = array(1.0, 2.0, 3); // A 3-vector of type Real[3]
  Integer[2,3] c = {{11, 12, 13}, {21, 22, 23}}; // A 2x3 matrix of type Integer[2,3]
  Real[1,1,3] d ={{{1.0, 2.0, 3.0}}}; // A 1x1x3 array of type Real[1,1,3]
  Real[3] v = array(1, 2, 3.0); // The vector v is equal to {1.,2.,3.}
  parameter Angle alpha = 2.0; // The expanded type of alpha is Real
  Real[3] f = array(alpha, 2, 3.0); // A 3-vector of type Real[3]
  Angle[3] A = {1.0, alpha, 4}; // The expanded type of A is Real[3]
end ArrayConstruct1;

// Result:
// class ArrayConstruct1
//   Integer a[1];
//   Integer a[2];
//   Integer a[3];
//   Real b[1];
//   Real b[2];
//   Real b[3];
//   Integer c[1,1];
//   Integer c[1,2];
//   Integer c[1,3];
//   Integer c[2,1];
//   Integer c[2,2];
//   Integer c[2,3];
//   Real d[1,1,1];
//   Real d[1,1,2];
//   Real d[1,1,3];
//   Real v[1];
//   Real v[2];
//   Real v[3];
//   parameter Real alpha(unit = "rad") = 2.0;
//   Real f[1];
//   Real f[2];
//   Real f[3];
//   Real A[1](unit = "rad");
//   Real A[2](unit = "rad");
//   Real A[3](unit = "rad");
// equation
//   a = {1, 2, 3};
//   b = {1.0, 2.0, 3};
//   c = {{11, 12, 13}, {21, 22, 23}};
//   d = {{{1.0, 2.0, 3.0}}};
//   v = {1.0, 2.0, 3.0};
//   f = {alpha, 2, 3.0};
//   A = {1.0, alpha, 4.0};
// end ArrayConstruct1;
// endResult
