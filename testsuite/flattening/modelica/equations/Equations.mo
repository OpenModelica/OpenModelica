// name:     Equations
// keywords: equation
// status:   correct
//
// Drmodelica:
//

class Equations
  Real x(start = 2);        // Modification equation
  constant Integer one = 1;      // Declaration equation
equation
  x = 3*one;            // Normal equation
end Equations;


// Result:
// class Equations
//   Real x(start = 2.0);
//   constant Integer one = 1;
// equation
//   x = 3.0;
// end Equations;
// [flattening/modelica/equations/Equations.mo:9:3-9:20:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/Equations.mo:10:3-10:27:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/Equations.mo:12:3-12:12:writable] Warning: Equation sections are deprecated in class.
//
// endResult
