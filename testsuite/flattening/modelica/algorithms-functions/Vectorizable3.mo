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
//   y := x + 1.0;
// end foo;
//
// class Vectorizable3
//   Real x[1,1];
//   Real x[1,2];
//   Real x[2,1];
//   Real x[2,2];
// equation
//   x = array(array(foo({{1.0, 2.0}, {3.0, 4.0}}[$i0,$i1]) for $i1 in 1:2) for $i0 in 1:2);
// end Vectorizable3;
// endResult
