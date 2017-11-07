// name: RedeclareMod1
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

model RedeclareMod1
  C c;
end RedeclareMod1;

// Result:
// class RedeclareMod1
//   Real c.x;
//   Real c.a.x = c.x;
// end RedeclareMod1;
// endResult
