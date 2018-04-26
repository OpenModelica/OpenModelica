// name: ceval2.mo
// status: correct
// cflags: -d=newInst

model A
  parameter Integer n = 1;
  parameter Integer m = 2+n;
  Real x[m] = fill(1.0, m);
end A;

// Result:
// class A
//   parameter Integer n = 1;
//   parameter Integer m = 3;
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = {1.0, 1.0, 1.0};
// end A;
// endResult
