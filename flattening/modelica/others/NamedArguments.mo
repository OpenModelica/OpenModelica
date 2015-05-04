// name:     NamedArguments
// keywords: function named arguments
// status:   correct
//
// Test different ways of calling a function with named and positional arguments.
//

function foo
  input Real x;
  input Real y;
  output Real z;
algorithm
  z:=x+y;
end foo;

model test
  Real w,v;
  Real x=foo(2,y=w);
  Real y=foo(x=v,y=w);
  Real z=foo(y=v,x=w);
  Real z2=foo(w,v);
end test;


// Result:
// function foo
//   input Real x;
//   input Real y;
//   output Real z;
// algorithm
//   z := x + y;
// end foo;
//
// class test
//   Real w;
//   Real v;
//   Real x = foo(2.0, w);
//   Real y = foo(v, w);
//   Real z = foo(w, v);
//   Real z2 = foo(w, v);
// end test;
// endResult
