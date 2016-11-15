// name: dim3.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//


model A
  parameter Integer n;
  Real x[n] = {1, 2, 3};
end A;

// Result:
// class A
//   parameter Integer n;
// end A;
// endResult
