// name: dim19.mo
// keywords:
// status: correct
//
//

model A
  parameter Integer n[3] = {1, 2, 3};
  parameter Integer m = n[2];
  Real x[m];
end A;

// Result:
// class A
//   final parameter Integer n[1] = 1;
//   final parameter Integer n[2] = 2;
//   final parameter Integer n[3] = 3;
//   final parameter Integer m = 2;
//   Real x[1];
//   Real x[2];
// end A;
// endResult
