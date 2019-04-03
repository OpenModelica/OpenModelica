// name: Algorithm2
// keywords: 
// status: correct
// cflags: -d=newInst
//

model Algorithm2
  Real x;
  Real y;
  Real z;
  Real a;
  Real b;
algorithm
  x := 1.0;
  y := x;
  z := x + y;
algorithm
  a := 1.0;
  b := 2.0;
end Algorithm2;

// Result:
// class Algorithm2
//   Real x;
//   Real y;
//   Real z;
//   Real a;
//   Real b;
// algorithm
//   x := 1.0;
//   y := x;
//   z := x + y;
// algorithm
//   a := 1.0;
//   b := 2.0;
// end Algorithm2;
// endResult
