// name:     EquationComponent5
// keywords: equation
// status:   correct
//
// When an equation is between to complex types, the equation is split
// into separate equations for the components.
//

class EquationComponent5
  record R
    Real x,y;
  end R;
  R a;
  R b = a;
end EquationComponent5;

// Result:
// class EquationComponent5
//   Real a.x;
//   Real a.y;
//   Real b.x = a.x;
//   Real b.y = a.y;
// end EquationComponent5;
// [flattening/modelica/equations/EquationComponent5.mo:13:3-13:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationComponent5.mo:14:3-14:10:writable] Warning: Components are deprecated in class.
//
// endResult
