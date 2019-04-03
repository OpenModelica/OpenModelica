// name: Algorithm1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model Algorithm1
  Real x;
  Real y;
  Real z;
algorithm
  x := 1.0;
  y := x;
  z := x + y;
end Algorithm1;

// Result:
// class Algorithm1
//   Real x;
//   Real y;
//   Real z;
// algorithm
//   x := 1.0;
//   y := x;
//   z := x + y;
// end Algorithm1;
// endResult
