// name:     Vectorizable1
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


model Vectorizable1
  Real x[3];
  Real s[2];
  Real a,b,c;
equation
  x=foo({a,b,c})+foo({1,2,3});
  der(s)=-fill(1,2);
end Vectorizable1;

// Result:
// function foo
//   input Real x;
//   output Real y;
// algorithm
//   y := 1.0 + x;
// end foo;
//
// class Vectorizable1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real s[1];
//   Real s[2];
//   Real a;
//   Real b;
//   Real c;
// equation
//   x[1] = foo(a) + 2.0;
//   x[2] = foo(b) + 3.0;
//   x[3] = foo(c) + 4.0;
//   der(s[1]) = -1.0;
//   der(s[2]) = -1.0;
// end Vectorizable1;
// endResult
