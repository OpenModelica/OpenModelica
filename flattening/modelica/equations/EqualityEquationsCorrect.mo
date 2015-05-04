// name:     EqualityEquationsCorrect
// keywords: equation
// status:   correct
//
// Not yet implemented


function f
  input Real a;
  input Real b;
  output Real c;
  output Real d;
  output Real e;
algorithm
  c := a + b;
  d := a - b;
  e := a * b;
end f;


class EqualityEquationsCorrect
  Real x;
  Real y;
  Real z;
  Real u;
  Real v = 2;
equation
  u = v;                    // Equality equations between two expressions
  (x, y, z) = f(1.0, 2.0);        // Correct!
end EqualityEquationsCorrect;


// Result:
// function f
//   input Real a;
//   input Real b;
//   output Real c;
//   output Real d;
//   output Real e;
// algorithm
//   c := a + b;
//   d := a - b;
//   e := a * b;
// end f;
//
// class EqualityEquationsCorrect
//   Real x;
//   Real y;
//   Real z;
//   Real u;
//   Real v = 2.0;
// equation
//   u = v;
//   (x, y, z) = (3.0, -1.0, 2.0);
// end EqualityEquationsCorrect;
// endResult
