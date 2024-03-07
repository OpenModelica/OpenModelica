// name: redeclare2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  replaceable Real x;
end A;

model B
  A a(redeclare parameter Real x = 0);
end B;

// Result:
// class B
//   parameter Real a.x = 0.0;
// end B;
// endResult
