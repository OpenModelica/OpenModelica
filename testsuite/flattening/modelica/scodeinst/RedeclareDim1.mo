// name: RedeclareDim1
// keywords: redeclare
// status: correct
//

model A
  Real x[:];
end A;

model RedeclareDim1
  parameter Integer n = 3;
  A a(redeclare Real x[n]);
end RedeclareDim1;

// Result:
// class RedeclareDim1
//   final parameter Integer n = 3;
//   Real a.x[1];
//   Real a.x[2];
//   Real a.x[3];
// end RedeclareDim1;
// endResult
