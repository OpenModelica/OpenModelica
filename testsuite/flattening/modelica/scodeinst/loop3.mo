// name: loop3.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  parameter Integer n = 2;
  parameter Real x[2, 3];
  parameter Integer i = size(x, n);
end A;

// Result:
// class A
//   parameter Integer n = 2;
//   parameter Real x[1,1];
//   parameter Real x[1,2];
//   parameter Real x[1,3];
//   parameter Real x[2,1];
//   parameter Real x[2,2];
//   parameter Real x[2,3];
//   parameter Integer i = size(x, n);
// end A;
// endResult
