// name:     ConstrainingType2
// keywords: replaceable
// status:   incorrect
//
// Modifiers are applied to the constraining type,
// and thus it is illegal to set parameters
// in the actual class that are not found in
// the constraining type.

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

model ConstrainingType2
  A a(c(C=1e-7)); // Illegal since no C in constraining type of c.
  A b(redeclare Resistor c(R=2),redeclare Conductor r(C=1e-5));
  Ground g;
  ConstantSource s(U=1);
equation
  connect(s.a,g.a);
  connect(s.b,a.a);
  connect(a.b,b.a);
  connect(b.b,s.a);
end ConstrainingType2;


