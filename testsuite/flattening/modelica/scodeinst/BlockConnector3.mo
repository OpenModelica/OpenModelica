// name: BlockConnector3
// keywords:
// status: correct
//
// Checks that the input/output restriction on connectors in a block only
// applies to public connectors, and not to parameters and constants in them.
//

connector Pin
  Real v;
  flow Real i;
end Pin;

connector RealSig = Real;

connector C
  parameter Integer n = 1;
  constant Real k = 2.0;
  input Real u;
  output Real y;
end C;

record R
  Real a;
  Real b;
end R;

connector RC = R;

block B
  C c;
  input RC rc;
  input RealSig u;
  output RealSig y;
  Real x;
protected
  Pin p;
equation
  p.v = c.u;
  x = p.v + rc.a + rc.b;
  c.y = x;
  y = c.k * u;
end B;

model M
  Pin p;
end M;

model BlockConnector3
  B b;
  M m;
end BlockConnector3;

// Result:
// class BlockConnector3
//   parameter Integer b.c.n = 1;
//   constant Real b.c.k = 2.0;
//   Real b.c.u;
//   Real b.c.y;
//   Real b.rc.a;
//   Real b.rc.b;
//   Real b.u;
//   Real b.y;
//   Real b.x;
//   protected Real b.p.v;
//   protected Real b.p.i;
//   Real m.p.v;
//   Real m.p.i;
// equation
//   b.p.i = 0.0;
//   m.p.i = 0.0;
//   b.p.v = b.c.u;
//   b.x = b.p.v + b.rc.a + b.rc.b;
//   b.c.y = b.x;
//   b.y = 2.0 * b.u;
// end BlockConnector3;
// endResult
