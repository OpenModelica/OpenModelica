// name:     SimplifyBinary
// keywords: simplify
// status:   correct
//


model SimplifyBinary
  Real x(start=0);
  Real a,b,c,d,e,f,g,h,i;
  Real x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12;
equation
  10 = x+der(x);
  a = x-der(x);
  b = (a*x)/x;
  c = (a*x)/a;
  d = (-a*x)/x;
  e = (-a*x)/a;
  f = (a*(-x))/a;
  g = (a*x)/(-x);
  h = (a*x)/(-a);
  i = ((-a)*x)/(-a);
  x1 = x - (-1);
  x2 = -1*x;
  x3 = 1*x;
  x4 = (time - 1)*x + x;
  x5 = x + x*(1-time);
  x6 = (x*a) - (x*b);
  x7 = x1*x + (x4*x)*x6; //[(e1 * e2) op2 e] op1 [(e4 op2 e) * e6] => (e1*e2 op1 e4*e6) op2 e
  x8 = (x1*x*x3) - (x4*x)*x6; //[(e1 op2 e) * e3] op1 [(e4 op2 e) * e6] => (e1*e3 op1 e4*e6) op2 e
  x9 = (x/x2) - (x*x4); //(e / e2) op1 (e * e4) => (e * (1/e2)) op1 (e * e4 ) => e*(1/e2 op1 e4)
  x10 = (x*x2) - x/x4; //(e * e2) op1 (e / e4) => (e * e2) op1 (e * (1/ e4) ) => e*(e2 op1 (1/ e4))
  x11 = -x2+(((x*x2) - x/x4)/x);
  x12 = x*((x4*x1)+(x5*x1^2))*x;

end SimplifyBinary;

// Result:
// class SimplifyBinary
//   Real x(start = 0.0);
//   Real a;
//   Real b;
//   Real c;
//   Real d;
//   Real e;
//   Real f;
//   Real g;
//   Real h;
//   Real i;
//   Real x1;
//   Real x2;
//   Real x3;
//   Real x4;
//   Real x5;
//   Real x6;
//   Real x7;
//   Real x8;
//   Real x9;
//   Real x10;
//   Real x11;
//   Real x12;
// equation
//   10.0 = x + der(x);
//   a = x - der(x);
//   b = a;
//   c = x;
//   d = -a;
//   e = -x;
//   f = -x;
//   g = -a;
//   h = -x;
//   i = x;
//   x1 = 1.0 + x;
//   x2 = -x;
//   x3 = x;
//   x4 = x * time;
//   x5 = x * (2.0 - time);
//   x6 = x * (a - b);
//   x7 = x * (x1 + x4 * x6);
//   x8 = x * (x1 * x3 - x4 * x6);
//   x9 = (1.0 / x2 - x4) * x;
//   x10 = (x2 + (-1.0) / x4) * x;
//   x11 = (-1.0) / x4;
//   x12 = (x4 * x1 + x5 * x1 ^ 2.0) * x ^ 2.0;
// end SimplifyBinary;
// endResult
