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
//   w = array(foo(x[$i0], y[$i0], z) for $i0 in 1:2);
// end Vectorizable5;
// endResult
