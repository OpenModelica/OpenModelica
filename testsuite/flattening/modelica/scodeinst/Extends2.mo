// name: Extends2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
end A;

model B
  Real y;
end B;

model C
  Real z;
end C;

model Extends2
  Real a;
  extends A;
  Real b;
  extends B;
  Real c;
  extends C;
  Real d;
end Extends2;

// Result:
// class Extends2
//   Real a;
//   Real x;
//   Real b;
//   Real y;
//   Real c;
//   Real z;
//   Real d;
// end Extends2;
// endResult
