// name:     Pow
// keywords: pow, exponentation, simplification, bug1161
// status:   correct
// cflags: -d=-newInst
//
// Test fix for bug #1161: http://openmodelica.ida.liu.se:8080/cb/issue/1161?navigation=true
//

model Pow
  parameter Integer pi = 3;
  parameter Real pr = 4.0;
  Real i, j, k, l, m, n, o, p;
equation
  i = 3 * (2 ^ pi);
  j = 3 * (pi ^ 2);
  k = 3.0 * (2 ^ pr);
  l = 3.0 * (pr ^ 2);
  m = (3.0 ^ pr) ^ (1/pr);
  n = time ^ (2 ^ 3);
  o = (time ^ 2) ^ 3;
  p = (time ^ 6) ^ 0.5;
end Pow;

// Result:
// class Pow
//   parameter Integer pi = 3;
//   parameter Real pr = 4.0;
//   Real i;
//   Real j;
//   Real k;
//   Real l;
//   Real m;
//   Real n;
//   Real o;
//   Real p;
// equation
//   i = 3.0 * 2.0 ^ /*Real*/(pi);
//   j = 3.0 * /*Real*/(pi) ^ 2.0;
//   k = 3.0 * 2.0 ^ pr;
//   l = 3.0 * pr ^ 2.0;
//   m = 3.0;
//   n = time ^ 8.0;
//   o = time ^ 6.0;
//   p = abs(time) ^ 3.0;
// end Pow;
// endResult
