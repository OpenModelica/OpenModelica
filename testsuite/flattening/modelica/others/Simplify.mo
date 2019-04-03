// name:     Simplify
// keywords: simplify
// status:   correct
//


model Simplify
  Real x(start=1);
  parameter Real a=2;
  parameter Real b=3;
  parameter Real c=4;
  parameter Real d=5;
  parameter Real e=6;
  parameter Real f=7;
equation
  der(x) = sin(time)/a/b/c/d/e/f;
end Simplify;


// Result:
// class Simplify
//   Real x(start = 1.0);
//   parameter Real a = 2.0;
//   parameter Real b = 3.0;
//   parameter Real c = 4.0;
//   parameter Real d = 5.0;
//   parameter Real e = 6.0;
//   parameter Real f = 7.0;
// equation
//   der(x) = sin(time) / (e * c * a * b * d * f);
// end Simplify;
// endResult
