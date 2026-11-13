// name:     Redeclare3
// keywords: redeclare
// status:   correct
//

model A
  Real x;
equation
  x = 1;
end A;

model B
  Real x,y;
equation
  y = x;
end B;

model C
  replaceable model Q = A;
  Q x;
end C;

model Redeclare3
  C c(redeclare class Q = B(y=1));
end Redeclare3;






// Result:
// class Redeclare3
//   Real c.x.x;
//   Real c.x.y = 1.0;
// equation
//   c.x.y = c.x.x;
// end Redeclare3;
// endResult
