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
// function EquationComponent5.R "Automatically generated record constructor for EquationComponent5.R"
//   input Real x;
//   input Real y;
//   output R res;
// end EquationComponent5.R;
//
// class EquationComponent5
//   Real a.x;
//   Real a.y;
//   Real b.x = a.x;
//   Real b.y = a.y;
// end EquationComponent5;
// endResult
