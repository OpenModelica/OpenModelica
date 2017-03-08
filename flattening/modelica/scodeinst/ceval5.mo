// name: ceval4.mo
// status: correct
// cflags: -d=newInst

model A
  parameter Real n = 3;
  parameter Integer m = n;
  Real x[m] = {1.0, 1.0, 1.0}; //fill(1.0, m);
end A;

// Result:
// class A
//   parameter Real n = 3;
//   parameter Integer m = n;
//   Real x[1] = 1.0;
//   Real x[2] = 1.0;
//   Real x[3] = 1.0;
// end A;
// endResult
