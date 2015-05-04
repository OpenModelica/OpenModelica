// name: FunctionCall
// keywords: function
// status: correct
//
// Tests function calls
//

function f
  input Integer x;
  output Integer y;
algorithm
  y := x + 2;
end f;

model FunctionCall
  Integer x;
  Integer y;
equation
  x = 2;
  y = f(x);
end FunctionCall;

// Result:
// function f
//   input Integer x;
//   output Integer y;
// algorithm
//   y := 2 + x;
// end f;
//
// class FunctionCall
//   Integer x;
//   Integer y;
// equation
//   x = 2;
//   y = f(x);
// end FunctionCall;
// endResult
