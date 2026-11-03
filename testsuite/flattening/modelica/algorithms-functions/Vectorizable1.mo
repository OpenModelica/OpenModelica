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
//   y := x + 1.0;
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
//   x = array(foo({a, b, c}[$i0]) for $i0 in 1:3) + array(foo({1.0, 2.0, 3.0}[$i1]) for $i1 in 1:3);
//   der(s[1]) = -1.0;
//   der(s[2]) = -1.0;
// end Vectorizable1;
// endResult
