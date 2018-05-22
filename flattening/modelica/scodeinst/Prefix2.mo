// name: Prefix2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
end A;

model B
  Real y;
  A a(x = y);
end B;

model Prefix2
  B b[2];
end Prefix2;

// Result:
// class Prefix2
//   Real b[1].y;
//   Real b[1].a.x = b[1].y;
//   Real b[2].y;
//   Real b[2].a.x = b[2].y;
// end Prefix2;
// endResult
