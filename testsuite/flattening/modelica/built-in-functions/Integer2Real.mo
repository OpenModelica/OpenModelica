// name:     Integer2Real
// keywords: type
// status:   correct
//
// Automatic conversion from Integer to Real.
//

class Integer2Real
  Integer n;
  Real a;
equation
  n = 5;
  a = n / 2;
end Integer2Real;

// Result:
// class Integer2Real
//   Integer n;
//   Real a;
// equation
//   n = 5;
//   a = /*Real*/(n) / 2.0;
// end Integer2Real;
// [flattening/modelica/built-in-functions/Integer2Real.mo:9:3-9:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/built-in-functions/Integer2Real.mo:10:3-10:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/built-in-functions/Integer2Real.mo:12:3-12:8:writable] Warning: Equation sections are deprecated in class.
//
// endResult
