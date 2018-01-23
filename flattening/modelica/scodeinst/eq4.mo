// name: eq4.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

package P
  constant Integer n = 3;
end P;

model A
  Real x;
  parameter Real y;
equation
  x = y * P.n;
  y = x;
end A;

model B
  A a1[3](y = {1, 2, 3});
  A a2[3](each y = 4);
end B;

// Result:
// class B
//   Real a1[1].x;
//   parameter Real a1[1].y = 1.0;
//   Real a1[2].x;
//   parameter Real a1[2].y = 2.0;
//   Real a1[3].x;
//   parameter Real a1[3].y = 3.0;
//   Real a2[1].x;
//   parameter Real a2[1].y = 4.0;
//   Real a2[2].x;
//   parameter Real a2[2].y = 4.0;
//   Real a2[3].x;
//   parameter Real a2[3].y = 4.0;
// equation
//   a1[1].x = a1[1].y * 3.0;
//   a1[1].y = a1[1].x;
//   a1[2].x = a1[2].y * 3.0;
//   a1[2].y = a1[2].x;
//   a1[3].x = a1[3].y * 3.0;
//   a1[3].y = a1[3].x;
//   a2[1].x = a2[1].y * 3.0;
//   a2[1].y = a2[1].x;
//   a2[2].x = a2[2].y * 3.0;
//   a2[2].y = a2[2].x;
//   a2[3].x = a2[3].y * 3.0;
//   a2[3].y = a2[3].x;
// end B;
// endResult
