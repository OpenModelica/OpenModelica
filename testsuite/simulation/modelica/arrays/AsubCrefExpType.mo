// name:     AsubCrefExpType
// keywords: asub cref type
// status:   correct
//
// Tests the type of a cref exp inside of a asub exp
//

model A
  parameter Real J(min=0,start=1);
end A;

model B
  parameter Real I[3, 3]= {{1,0,0},{0,1,0},{0,0,1}};
end B;

model AsubCrefExpType
  B b;
  A a(J=b.I[1, 1]);
end AsubCrefExpType;

// Result:
// class AsubCrefExpType
//   parameter Real b.I[1,1] = 1.0;
//   parameter Real b.I[1,2] = 0.0;
//   parameter Real b.I[1,3] = 0.0;
//   parameter Real b.I[2,1] = 0.0;
//   parameter Real b.I[2,2] = 1.0;
//   parameter Real b.I[2,3] = 0.0;
//   parameter Real b.I[3,1] = 0.0;
//   parameter Real b.I[3,2] = 0.0;
//   parameter Real b.I[3,3] = 1.0;
//   parameter Real a.J(min = 0.0, start = 1.0) = b.I[1,1];
// end AsubCrefExpType;
// endResult
