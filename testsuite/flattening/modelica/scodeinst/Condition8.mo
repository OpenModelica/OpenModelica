// name: Condition8
// keywords:
// status: correct
//
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c;
end A;

model B
  parameter Boolean b;
  A a if b;
  C c;
equation
  connect(a.c, c);
end B;

model Condition8
  B b[3](b = {true, false, true});
end Condition8;

// Result:
// class Condition8
//   final parameter Boolean b[1].b = true;
//   Real b[1].a.c.e;
//   Real b[1].a.c.f;
//   Real b[1].c.e;
//   Real b[1].c.f;
//   final parameter Boolean b[2].b = false;
//   Real b[2].c.e;
//   Real b[2].c.f;
//   final parameter Boolean b[3].b = true;
//   Real b[3].a.c.e;
//   Real b[3].a.c.f;
//   Real b[3].c.e;
//   Real b[3].c.f;
// equation
//   b[1].a.c.e = b[1].c.e;
//   b[3].a.c.e = b[3].c.e;
//   b[1].a.c.f - b[1].c.f = 0.0;
//   b[1].c.f = 0.0;
//   b[2].c.f = 0.0;
//   b[3].a.c.f - b[3].c.f = 0.0;
//   b[3].c.f = 0.0;
// end Condition8;
// endResult
