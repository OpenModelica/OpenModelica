// name:     ConstrainingType1
// keywords: replaceable
// status:   correct
//
// Demonstrates that it is sufficient that
// a redeclare is a sub-type of the constraining
// type, and how replaceable, redeclare,
// and constraing_clause can be used together.

connector OnePin
  flow Real i;
  Real v;
end OnePin;

model Ground
  OnePin a;
equation
  a.v=0;
end Ground;

model ConstantSource
  extends OnePort;
  parameter Real U;
equation
  v=U;
end ConstantSource;

model TwoPin
  OnePin a,b;
  Real v;
equation
  v=b.v-a.v;
end TwoPin;

model OnePort
  extends TwoPin;
  Real i;
equation
  i=a.i;
  a.i+b.i=0;
end OnePort;

model Resistor
  extends OnePort;
  parameter Real R;
equation
  v=R*i;
end Resistor;

model Conductor
  extends OnePort;
  parameter Real C;
equation
  C*der(v)=i;
end Conductor;

model A
  extends TwoPin;
  replaceable Resistor r(R=1) extends TwoPin;
  replaceable Conductor c(C=1e-4) extends TwoPin;
equation
  connect(a,r.a);
  connect(r.b,c.a);
  connect(c.b,b);
end A;

model A2
  extends A(redeclare Conductor c);
end A2;

model ConstrainingType1
  A2 a(c(C=1e-7));
  A b(redeclare Resistor c(R=2),redeclare Conductor r(C=1e-5));
  Ground g;
  ConstantSource s(U=10);
equation
  connect(s.a,g.a);
  connect(s.b,a.a);
  connect(a.b,b.a);
  connect(b.b,s.a);
end ConstrainingType1;

// Result:
// class ConstrainingType1
//   Real a.a.i;
//   Real a.a.v;
//   Real a.b.i;
//   Real a.b.v;
//   Real a.v;
//   Real a.r.a.i;
//   Real a.r.a.v;
//   Real a.r.b.i;
//   Real a.r.b.v;
//   Real a.r.v;
//   Real a.r.i;
//   parameter Real a.r.R = 1.0;
//   Real a.c.a.i;
//   Real a.c.a.v;
//   Real a.c.b.i;
//   Real a.c.b.v;
//   Real a.c.v;
//   Real a.c.i;
//   parameter Real a.c.C = 0.0000001;
//   Real b.a.i;
//   Real b.a.v;
//   Real b.b.i;
//   Real b.b.v;
//   Real b.v;
//   Real b.r.a.i;
//   Real b.r.a.v;
//   Real b.r.b.i;
//   Real b.r.b.v;
//   Real b.r.v;
//   Real b.r.i;
//   parameter Real b.r.C = 0.00001;
//   Real b.c.a.i;
//   Real b.c.a.v;
//   Real b.c.b.i;
//   Real b.c.b.v;
//   Real b.c.v;
//   Real b.c.i;
//   parameter Real b.c.R = 2.0;
//   Real g.a.i;
//   Real g.a.v;
//   Real s.a.i;
//   Real s.a.v;
//   Real s.b.i;
//   Real s.b.v;
//   Real s.v;
//   Real s.i;
//   parameter Real s.U = 10.0;
// equation
//   a.r.v = a.r.R * a.r.i;
//   a.r.i = a.r.a.i;
//   a.r.a.i + a.r.b.i = 0.0;
//   a.r.v = a.r.b.v - a.r.a.v;
//   a.c.C * der(a.c.v) = a.c.i;
//   a.c.i = a.c.a.i;
//   a.c.a.i + a.c.b.i = 0.0;
//   a.c.v = a.c.b.v - a.c.a.v;
//   a.v = a.b.v - a.a.v;
//   b.r.C * der(b.r.v) = b.r.i;
//   b.r.i = b.r.a.i;
//   b.r.a.i + b.r.b.i = 0.0;
//   b.r.v = b.r.b.v - b.r.a.v;
//   b.c.v = b.c.R * b.c.i;
//   b.c.i = b.c.a.i;
//   b.c.a.i + b.c.b.i = 0.0;
//   b.c.v = b.c.b.v - b.c.a.v;
//   b.v = b.b.v - b.a.v;
//   g.a.v = 0.0;
//   s.v = s.U;
//   s.i = s.a.i;
//   s.a.i + s.b.i = 0.0;
//   s.v = s.b.v - s.a.v;
//   a.a.i + s.b.i = 0.0;
//   a.b.i + b.a.i = 0.0;
//   (-a.a.i) + a.r.a.i = 0.0;
//   a.r.b.i + a.c.a.i = 0.0;
//   (-a.b.i) + a.c.b.i = 0.0;
//   a.a.v = a.r.a.v;
//   a.c.a.v = a.r.b.v;
//   a.b.v = a.c.b.v;
//   b.b.i + g.a.i + s.a.i = 0.0;
//   (-b.a.i) + b.r.a.i = 0.0;
//   b.r.b.i + b.c.a.i = 0.0;
//   (-b.b.i) + b.c.b.i = 0.0;
//   b.a.v = b.r.a.v;
//   b.c.a.v = b.r.b.v;
//   b.b.v = b.c.b.v;
//   b.b.v = g.a.v;
//   b.b.v = s.a.v;
//   a.a.v = s.b.v;
//   a.b.v = b.a.v;
// end ConstrainingType1;
// endResult
