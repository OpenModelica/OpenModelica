// name: DimRagged3
// keywords:
// status: correct
// cflags: --checkModel
//
// Array constructors over a ragged dimension in the relaxed frontend used by
// checkModel.
//

model Lay
  parameter Integer n;
  parameter Real m[n] = {1/n for i in 1:n};
  parameter Real m2[n] = 2*{1/n for i in 1:n};
end Lay;

model Con
  parameter Integer n;
  Lay l(n = n);
end Con;

model DimRagged3
  Lay a[2](n = {2, 3});
  Con c[2](n = {2, 3});
end DimRagged3;

// Result:
// class DimRagged3
//   final parameter Integer a[1].n = 2;
//   parameter Real a[1].m[1] = 0.5;
//   parameter Real a[1].m[2] = 0.5;
//   parameter Real a[1].m2[1] = 1.0;
//   parameter Real a[1].m2[2] = 1.0;
//   final parameter Integer a[2].n = 3;
//   parameter Real a[2].m[1] = 0.3333333333333333;
//   parameter Real a[2].m[2] = 0.3333333333333333;
//   parameter Real a[2].m[3] = 0.3333333333333333;
//   parameter Real a[2].m2[1] = 0.6666666666666666;
//   parameter Real a[2].m2[2] = 0.6666666666666666;
//   parameter Real a[2].m2[3] = 0.6666666666666666;
//   final parameter Integer c[1].n = 2;
//   final parameter Integer c[1].l.n = 2;
//   parameter Real c[1].l.m[1] = 0.5;
//   parameter Real c[1].l.m[2] = 0.5;
//   parameter Real c[1].l.m2[1] = 1.0;
//   parameter Real c[1].l.m2[2] = 1.0;
//   final parameter Integer c[2].n = 3;
//   final parameter Integer c[2].l.n = 3;
//   parameter Real c[2].l.m[1] = 0.3333333333333333;
//   parameter Real c[2].l.m[2] = 0.3333333333333333;
//   parameter Real c[2].l.m[3] = 0.3333333333333333;
//   parameter Real c[2].l.m2[1] = 0.6666666666666666;
//   parameter Real c[2].l.m2[2] = 0.6666666666666666;
//   parameter Real c[2].l.m2[3] = 0.6666666666666666;
// end DimRagged3;
// endResult
