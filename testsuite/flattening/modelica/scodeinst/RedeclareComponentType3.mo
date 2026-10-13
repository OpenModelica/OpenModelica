// name: RedeclareComponentType3
// keywords:
// status: correct
//
// Checks that components can be redeclared with types that are derived from
// the same basic type.
//

type Voltage = Real(unit = "V");

type T
  extends Real;
end T;

type E = enumeration(a, b);

record R1
  Real x;
end R1;

record R2
  extends R1;
  Real y;
end R2;

model A
  replaceable Real r = 1;
  replaceable Voltage v = 1;
  replaceable Real t = 1;
  replaceable Integer i = 1;
  replaceable Boolean b = true;
  replaceable String s = "s";
  replaceable E e = E.a;
  replaceable R1 rec(x = 1);
end A;

model RedeclareComponentType3
  A a(redeclare Voltage r, redeclare Real v, redeclare T t = 2,
      redeclare Integer i, redeclare Boolean b, redeclare String s,
      redeclare E e = E.b, redeclare R2 rec(y = 2));
end RedeclareComponentType3;

// Result:
// class RedeclareComponentType3
//   Real a.r(unit = "V") = 1.0;
//   Real a.v = 1.0;
//   Real a.t = 2.0;
//   Integer a.i = 1;
//   Boolean a.b = true;
//   String a.s = "s";
//   enumeration(a, b) a.e = E.b;
//   Real a.rec.x = 1.0;
//   Real a.rec.y = 2.0;
// end RedeclareComponentType3;
// endResult
