// name: Algorithm3
// keywords: 
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
  Real y;
algorithm
  x := 4.0;
  y := 3.5;
end A;

model Algorithm3
  Real x;
  Real y;
  Real z;
  A a;
algorithm
  x := 1.0;
  y := x;
  z := x + y;
end Algorithm3;

// Result:
// class Algorithm3
//   Real x;
//   Real y;
//   Real z;
//   Real a.x;
//   Real a.y;
// algorithm
//   a.x := 4.0;
//   a.y := 3.5;
// algorithm
//   x := 1.0;
//   y := x;
//   z := x + y;
// end Algorithm3;
// endResult
