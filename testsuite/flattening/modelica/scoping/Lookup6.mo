// name:     Lookup6
// keywords: scoping
// status:   correct
//
// The constant 'a' is hidden in class 'B' after the declaration
// of 'B.a'.
//

class Lookup6
  constant Real a = 3.0;
  class B
    Real a;
  equation
    a = -a;
  end B;
  B b;
end Lookup6;

// Result:
// class Lookup6
//   constant Real a = 3.0;
//   Real b.a;
// equation
//   b.a = -b.a;
// end Lookup6;
// [flattening/modelica/scoping/Lookup6.mo:12:5-12:11:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/Lookup6.mo:14:5-14:11:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/scoping/Lookup6.mo:10:3-10:24:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/Lookup6.mo:16:3-16:6:writable] Warning: Components are deprecated in class.
//
// endResult
