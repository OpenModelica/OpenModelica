// name: ExtendSections
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that sections are inherited correctly.
//


model Base
  Real x;
  Real y;
  Real z;
  Real w;
equation
  x = 4;
initial equation
  y = 2;
algorithm
  z := 3;
initial algorithm
  w := 5;
end Base;

model ExtendSections
  Real a;
  Real b;
  Real c;
  Real d;
  extends Base;
equation
  a = 1;
initial equation
  b = 2;
algorithm
  c := 3;
initial algorithm
  d := 4;
end ExtendSections;

// Result:
// class ExtendSections
//   Real a;
//   Real b;
//   Real c;
//   Real d;
//   Real x;
//   Real y;
//   Real z;
//   Real w;
// initial equation
//   b = 2.0;
//   y = 2.0;
// initial algorithm
//   w := 5.0;
// initial algorithm
//   d := 4.0;
// equation
//   a = 1.0;
//   x = 4.0;
// algorithm
//   c := 3.0;
// algorithm
//   z := 3.0;
// end ExtendSections;
// endResult
