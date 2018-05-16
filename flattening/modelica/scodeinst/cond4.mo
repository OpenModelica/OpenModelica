// name: cond4.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  parameter Boolean b;
  Real x if b;
end A;

model B
  parameter Boolean b = true;
  A a(b = b);
end B;

// Result:
// class B
//   parameter Boolean b = true;
//   parameter Boolean a.b = true;
//   Real a.x;
// end B;
// endResult
