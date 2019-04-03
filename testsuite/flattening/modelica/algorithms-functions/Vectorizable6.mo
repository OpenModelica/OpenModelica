// name:     Vectorizable6
// keywords: vectorized calls
// status:   correct
//
// This tests vectorized calls.
//

function foo
  input Real x;
  input Real x2[2];
  output Real y;
algorithm
  y:=x+1+x2[1]+2*x2[2];
end foo;


model Vectorizable6
  Real x[3];
equation
  {x}=foo(1,{{{1,2},{3,4},{5,6}}});
end Vectorizable6;

// function foo
// input Real x;
// input Real x2;
// output Real y;
// algorithm
//   y := x + 1.0 + x2[1] + 2.0 * x2[2];
// end foo;

// Result:
// function foo
//   input Real x;
//   input Real[2] x2;
//   output Real y;
// algorithm
//   y := 1.0 + x + x2[1] + 2.0 * x2[2];
// end foo;
//
// class Vectorizable6
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x[1] = 7.0;
//   x[2] = 13.0;
//   x[3] = 19.0;
// end Vectorizable6;
// endResult
