// name: mod1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model M
  Real z;
end M;

model A
  extends M;
  Real x;
end A;

model B
  extends A;
  Real y;
end B;

model C
  B b(x = 1.0, y = 2.0, z = 4.0);
end C;

// Result:
// class C
//   Real b.z = 4.0;
//   Real b.x = 1.0;
//   Real b.y = 2.0;
// end C;
// endResult
