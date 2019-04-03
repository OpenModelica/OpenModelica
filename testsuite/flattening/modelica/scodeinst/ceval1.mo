// name: ceval1.mo
// status: correct
// cflags: -d=newInst

model A
  parameter Integer n = (-1+2)*2-3+4;
  Real x[n] = {1.0, 2.0, 3.0};
end A;

// Result:
// class A
//   parameter Integer n = 3;
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = {1.0, 2.0, 3.0};
// end A;
// endResult
