// name:     Constant5
// keywords: declaration,array
// status:   correct
//
//
//

class Constant5
  Real x[integer(2.5)];
end Constant5;

// Result:
// class Constant5
//   Real x[1];
//   Real x[2];
// end Constant5;
// [flattening/modelica/declarations/Constant5.mo:9:3-9:23:writable] Warning: Components are deprecated in class.
//
// endResult
