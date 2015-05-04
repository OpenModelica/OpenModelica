// name:     EquationComponent2
// keywords: equation
// status:   correct
//
// When an equation is between to complex types, the equation is split
// into separate equations for the components.
//

class EquationComponent2
  record R
    Real x,y;
  end R;
  R a,b,c;
equation
  a = if true then b else c;
end EquationComponent2;
// Result:
// function EquationComponent2.R "Automatically generated record constructor for EquationComponent2.R"
//   input Real x;
//   input Real y;
//   output R res;
// end EquationComponent2.R;
//
// class EquationComponent2
//   Real a.x;
//   Real a.y;
//   Real b.x;
//   Real b.y;
//   Real c.x;
//   Real c.y;
// equation
//   a.x = b.x;
//   a.y = b.y;
// end EquationComponent2;
// endResult
