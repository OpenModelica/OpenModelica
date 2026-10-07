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
//   y := x + 1.0 + x2[1] + 2.0 * x2[2];
// end foo;
//
// class Vectorizable6
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   {x} = array(array(foo(1.0, {{{1.0, 2.0}, {3.0, 4.0}, {5.0, 6.0}}}[$i0,$i1]) for $i1 in 1:3) for $i0 in 1:1);
// end Vectorizable6;
// endResult
