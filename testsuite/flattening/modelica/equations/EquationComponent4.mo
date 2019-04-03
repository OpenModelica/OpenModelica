// name:     EquationComponent4
// keywords: equation
// status:   correct
//
// When an equation is between to complex types, the equation is split
// into separate equations for the components.
//

class EquationComponent4
  record R
    Real x,y;
  end R;
  R a,b,c;
equation
  (if true then a else b) = if true then b else c;
end EquationComponent4;
// Result:
// function EquationComponent4.R "Automatically generated record constructor for EquationComponent4.R"
//   input Real x;
//   input Real y;
//   output R res;
// end EquationComponent4.R;
//
// class EquationComponent4
//   Real a.x;
//   Real a.y;
//   Real b.x;
//   Real b.y;
//   Real c.x;
//   Real c.y;
// equation
//   a.x = b.x;
//   a.y = b.y;
// end EquationComponent4;
// endResult
