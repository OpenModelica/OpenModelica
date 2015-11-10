// name:     DerConstant1
// keywords: derivative
// status:   correct
//
// Modelica Spec 3.2: Section 3.7.2
// der(expr): For Real parameters and constants the result is a zero scalar or array of the same size as the variable.
//

class DerConstant1
  constant Real pa = 1;
  Real a = der(pa);
  Real b = der(1.0);
  parameter Real[1,2,1,2] pc = {{{{1,2}},{{3,4}}}};
  Real[1,2,1,2] c = der(pc);
  Real[1,2,1,2] d = der({{{{1.0,2.0}},{{3.0,4.0}}}});
end DerConstant1;

// Result:
// class DerConstant1
//   constant Real pa = 1.0;
//   Real a = 0.0;
//   Real b = 0.0;
//   parameter Real pc[1,1,1,1] = 1.0;
//   parameter Real pc[1,1,1,2] = 2.0;
//   parameter Real pc[1,2,1,1] = 3.0;
//   parameter Real pc[1,2,1,2] = 4.0;
//   Real c[1,1,1,1];
//   Real c[1,1,1,2];
//   Real c[1,2,1,1];
//   Real c[1,2,1,2];
//   Real d[1,1,1,1];
//   Real d[1,1,1,2];
//   Real d[1,2,1,1];
//   Real d[1,2,1,2];
// equation
//   c = {{{{0.0, 0.0}}, {{0.0, 0.0}}}};
//   d = {{{{0.0, 0.0}}, {{0.0, 0.0}}}};
// end DerConstant1;
// endResult
