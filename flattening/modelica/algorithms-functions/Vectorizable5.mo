// name:     Vectorizable5
// keywords: vectorized calls
// status:   correct
//
// This tests vectorized calls.
//

function foo
  input Real x;
  input Real y;
  input Real z;
  output Real w;
algorithm
  w:=x+y+z;
end foo;

model Vectorizable5
  Real x[2];
  Real y[2];
  Real z;
  Real w[2];
equation
  w=foo(x,y,z);
end Vectorizable5;


// function foo
// input Real x;
// input Real y;
// input Real z;
// output Real w;
// algorithm
//   w := x + y + z;
// end foo;

// Result:
// function foo
//   input Real x;
//   input Real y;
//   input Real z;
//   output Real w;
// algorithm
//   w := x + y + z;
// end foo;
//
// class Vectorizable5
//   Real x[1];
//   Real x[2];
//   Real y[1];
//   Real y[2];
//   Real z;
//   Real w[1];
//   Real w[2];
// equation
//   w[1] = foo(x[1], y[1], z);
//   w[2] = foo(x[2], y[2], z);
// end Vectorizable5;
// endResult
