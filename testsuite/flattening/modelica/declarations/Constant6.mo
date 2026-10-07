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
// class Constant6
//   Real x[1];
//   Real x[2];
// end Constant6;
// [flattening/modelica/declarations/Constant6.mo:16:3-16:17:writable] Warning: Components are deprecated in class.
//
// endResult
