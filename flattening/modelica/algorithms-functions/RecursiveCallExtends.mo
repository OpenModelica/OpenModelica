// name:     RecursiveCallExtends
// keywords: function, recursive, recursion, #2662
// status:   correct
//
// Tests that it's possible to create recursive functions via extends.
//

package Base
  partial function parent
    input Real a;
  algorithm
    g(a);
  end parent;
end Base;

function g
  extends Base.parent;
end g;

model RecursiveCallExtends
equation
  g(time);
end RecursiveCallExtends;

// Result:
// function g
//   input Real a;
// algorithm
//   return g(a);
// end g;
//
// class RecursiveCallExtends
// equation
//   g(time);
// end RecursiveCallExtends;
// endResult
