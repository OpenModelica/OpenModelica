// name: dim13
// keywords:
// status: correct
// cflags: -d=newInst
//


model A
  parameter Integer n = 3;
end A;

model B
  extends A;
  parameter Real x[n];
end B;

// Result:
// class B
//   parameter Integer n = 3;
//   parameter Real x[1];
//   parameter Real x[2];
//   parameter Real x[3];
// end B;
// endResult
