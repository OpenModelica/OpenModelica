// name: Connect1
// keywords:
// status: correct
// cflags: -d=newInst
//

connector C
  Real e;
  flow Real f;
end C;

model Connect1
  C c;    
end Connect1;

// Result:
// class Connect1
//   Real c.e;
//   Real c.f;
// equation
//   c.f = 0.0;
// end Connect1;
// endResult
