// name:     ArrayOuterParamExpand
// keywords: array inner outer parameter
// status:   correct
//
// Checks that outer parameters are expanded correctly.
//

model A
  outer parameter Real[3] p1;
  parameter Real[3] p2;
  Real v;
equation
  v = p1 * p2;
end A;

model ArrayOuterParamExpand
  inner parameter Real[3] p1;
  A a;
end ArrayOuterParamExpand;

// Result:
// class ArrayOuterParamExpand
//   parameter Real p1[1];
//   parameter Real p1[2];
//   parameter Real p1[3];
//   parameter Real a.p2[1];
//   parameter Real a.p2[2];
//   parameter Real a.p2[3];
//   Real a.v;
// equation
//   a.v = p1[1] * a.p2[1] + p1[2] * a.p2[2] + p1[3] * a.p2[3];
// end ArrayOuterParamExpand;
// endResult
