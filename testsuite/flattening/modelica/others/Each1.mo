// name:     Each1
// keywords: Each modifier
// status:   correct
//
// Testcase from Modelica specification.
//
model C
  parameter Real a[3];
  parameter Real d;
end C;
model B
  C c[5](each a={1,2,3},d={1,2,3,4,5});
end B;
// Result:
// class B
//   parameter Real c[1].a[1] = 1.0;
//   parameter Real c[1].a[2] = 2.0;
//   parameter Real c[1].a[3] = 3.0;
//   parameter Real c[1].d = 1.0;
//   parameter Real c[2].a[1] = 1.0;
//   parameter Real c[2].a[2] = 2.0;
//   parameter Real c[2].a[3] = 3.0;
//   parameter Real c[2].d = 2.0;
//   parameter Real c[3].a[1] = 1.0;
//   parameter Real c[3].a[2] = 2.0;
//   parameter Real c[3].a[3] = 3.0;
//   parameter Real c[3].d = 3.0;
//   parameter Real c[4].a[1] = 1.0;
//   parameter Real c[4].a[2] = 2.0;
//   parameter Real c[4].a[3] = 3.0;
//   parameter Real c[4].d = 4.0;
//   parameter Real c[5].a[1] = 1.0;
//   parameter Real c[5].a[2] = 2.0;
//   parameter Real c[5].a[3] = 3.0;
//   parameter Real c[5].d = 5.0;
// end B;
// endResult
