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
// endResult
