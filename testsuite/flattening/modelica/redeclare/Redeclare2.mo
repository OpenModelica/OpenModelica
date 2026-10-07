// name:     Redeclare2
// keywords: redeclare
// status:   correct
//
// Replaceable classes.

class A
  Real x;
equation
  x = 1.0;
end A;

class B
  Real x,y;
equation
  y = x;
end B;

class Redeclare2
  replaceable class Q = A;
  Q x;
end Redeclare2;

// Result:
// class Redeclare2
//   Real x.x;
// equation
//   x.x = 1.0;
// end Redeclare2;
// [flattening/modelica/redeclare/Redeclare2.mo:8:3-8:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/redeclare/Redeclare2.mo:10:3-10:10:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/redeclare/Redeclare2.mo:21:3-21:6:writable] Warning: Components are deprecated in class.
//
// endResult
