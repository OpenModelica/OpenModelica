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
//   a = b;
// end EquationComponent2;
// [flattening/modelica/equations/EquationComponent2.mo:13:3-13:10:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationComponent2.mo:15:3-15:28:writable] Warning: Equation sections are deprecated in class.
//
// endResult
