// name: mod13.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model D
  extends C;
  Real y = x;
end D;

model C
  parameter Real offset = 0;
  Real x;
equation
  x = offset;
end C;

model B
  parameter Real offset = 0;
  replaceable C c(final offset = offset);
end B;

model A
  parameter Real Vdc = 1;
  extends B(redeclare D c, offset = Vdc);
end A;

// Result:
// class A
//   parameter Real Vdc = 1.0;
//   parameter Real offset = Vdc;
//   final parameter Real c.offset = offset;
//   Real c.x;
//   Real c.y = c.x;
// equation
//   c.x = c.offset;
// end A;
// endResult
