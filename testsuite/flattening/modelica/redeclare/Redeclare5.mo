// name:     Redeclare5
// keywords: redeclare, bug #36
// status:   correct
//
model B
  parameter Real b=1.0;
  Real x;
end B;

model BB
  extends B;
equation
  der(x) = b;
end BB;

model C
  replaceable B d(b=5);
end C;

model D
  C c(redeclare BB d);
end D;


// Result:
// class D
//   parameter Real c.d.b = 5.0;
//   Real c.d.x;
// equation
//   der(c.d.x) = c.d.b;
// end D;
// endResult
