// name:     Redeclare2
// keywords: redeclare
// status:   correct
//
// Replaceable classes.

model A
  Real x;
equation
  x = 1.0;
end A;

model B
  Real x,y;
equation
  y = x;
end B;

model Redeclare2
  replaceable model Q = A;
  Q x;
end Redeclare2;

// Result:
// class Redeclare2
//   Real x.x;
// equation
//   x.x = 1.0;
// end Redeclare2;
// endResult
