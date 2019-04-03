// name:     Vectorizable3
// keywords: vectorized calls
// status:   correct
//
// This tests vectorized calls.
//

function foo
  input Real x;
  output Real y;
algorithm
  y:=x+1;
end foo;


model Vectorizable3
  Real x[2,2];
equation
  x=foo([1,2;3,4]);
end Vectorizable3;

// function foo
// input Real x;
// output Real y;
// algorithm
//   y := x + 1.0;
// end foo;

// Result:
// function foo
//   input Real x;
//   output Real y;
// algorithm
//   y := 1.0 + x;
// end foo;
//
// class Vectorizable3
//   Real x[1,1];
//   Real x[1,2];
//   Real x[2,1];
//   Real x[2,2];
// equation
//   x[1,1] = 2.0;
//   x[1,2] = 3.0;
//   x[2,1] = 4.0;
//   x[2,2] = 5.0;
// end Vectorizable3;
// endResult
