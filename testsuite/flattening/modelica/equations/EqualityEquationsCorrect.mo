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
// class EqualityEquationsCorrect
//   Real x;
//   Real y;
//   Real z;
//   Real u;
//   Real v = 2.0;
// equation
//   u = v;
//   x = 3.0;
//   y = -1.0;
//   z = 2.0;
// end EqualityEquationsCorrect;
// [flattening/modelica/equations/EqualityEquationsCorrect.mo:22:3-22:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EqualityEquationsCorrect.mo:23:3-23:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EqualityEquationsCorrect.mo:24:3-24:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EqualityEquationsCorrect.mo:25:3-25:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EqualityEquationsCorrect.mo:26:3-26:13:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EqualityEquationsCorrect.mo:28:3-28:8:writable] Warning: Equation sections are deprecated in class.
//
// endResult
