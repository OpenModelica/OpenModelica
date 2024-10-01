// name: RedeclareDim2
// keywords: redeclare
// status: correct
//

package P
  type RealArray = Real[:];
end P;

model RedeclareDim2
  parameter Integer n = 3;
  package MP = P(redeclare type RealArray = Real[n]);
  MP.RealArray x;
end RedeclareDim2;

// Result:
// class RedeclareDim2
//   final parameter Integer n = 3;
//   Real x[1];
//   Real x[2];
//   Real x[3];
// end RedeclareDim2;
// endResult
