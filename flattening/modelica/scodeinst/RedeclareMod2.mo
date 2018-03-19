// name: RedeclareMod2
// keywords:
// status: correct
// cflags: -d=newInst
//
// 

model A
  Real x;
end A;

model B
  replaceable A a;
end B;

model C
  Real x;
  extends B(redeclare A a(x = x));
end C;

model RedeclareMod2
  C c;
end RedeclareMod2;

// Result:
// class RedeclareMod2
//   Real c.x;
//   Real c.a.x = c.x;
// end RedeclareMod2;
// endResult
