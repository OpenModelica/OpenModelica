// name: dim19.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  parameter Integer n[3] = {1, 2, 3};
  parameter Integer m = n[2];
  Real x[m];
end A;

// Result:
// class A
//   parameter Integer n[1] = 1;
//   parameter Integer n[2] = 2;
//   parameter Integer n[3] = 3;
//   parameter Integer m = 2;
//   Real x[1];
//   Real x[2];
// end A;
// endResult
