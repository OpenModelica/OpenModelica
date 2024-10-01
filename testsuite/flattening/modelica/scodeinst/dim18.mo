// name: dim18
// keywords:
// status: correct
//

model A
  parameter Integer m = 2;
  parameter Integer n = m;
  Real x[n];
end A;

// Result:
// class A
//   final parameter Integer m = 2;
//   final parameter Integer n = 2;
//   Real x[1];
//   Real x[2];
// end A;
// endResult
