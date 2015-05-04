// name:     Function10
// keywords: function
// status:   correct
//
// This tests for bug in function instantiation. A function argument can have same identifier as
// function name.

function foo
  input Real x;
  output Real foo;
  external "C";
end foo;

model test
  Real x=foo(time);
end test;

// Result:
// function foo
//   input Real x;
//   output Real foo;
//
//   external "C" foo = foo(x);
// end foo;
//
// class test
//   Real x = foo(time);
// end test;
// endResult
