// name: redeclare2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  replaceable Real x;
end A;

model B
  A a(redeclare parameter Real x);
end B;

// Result:
// class B
//   parameter Real a.x;
// end B;
// endResult
