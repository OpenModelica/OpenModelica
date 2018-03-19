// name: RedeclareMod1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x = 1.0;
end A;

model RedeclareMod1
  A a(redeclare Real x);
end RedeclareMod1;


// Result:
// class RedeclareMod1
//   Real a.x = 1.0;
// end RedeclareMod1;
// endResult
