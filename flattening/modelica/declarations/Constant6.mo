// name:     Constant6
// keywords: declaration,array
// status:   correct
//
// Can you call functions in constant expressions?
//

function inc
  input Integer x;
  output Integer y;
algorithm
  y := x + 1;
end inc;

class Constant6
  Real x[inc(1)];
end Constant6;

// Result:
// function inc
//   input Integer x;
//   output Integer y;
// algorithm
//   y := 1 + x;
// end inc;
//
// class Constant6
//   Real x[1];
//   Real x[2];
// end Constant6;
// endResult
