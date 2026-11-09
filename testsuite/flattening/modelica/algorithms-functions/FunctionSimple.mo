// name: FunctionSimple
// keywords: function
// status: correct
//
// Tests simple function declaration and calling
//

function TestFunction
  input Integer i;
  output Integer o;
algorithm
  o := i;
end TestFunction;

model FunctionSimple
  Integer x,y;
equation
  x = 1;
  y = TestFunction(x);
end FunctionSimple;

// Result:
// function TestFunction
//   input Integer i;
//   output Integer o;
// algorithm
//   o := i;
// end TestFunction;
//
// class FunctionSimple
//   Integer x;
//   Integer y;
// equation
//   x = 1;
//   y = TestFunction(x);
// end FunctionSimple;
// endResult
