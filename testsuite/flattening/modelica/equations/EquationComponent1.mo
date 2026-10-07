// name:     EquationComponent1
// keywords: equation
// status:   correct
//
// When an equation is between to complex types, the equation is split
// into separate equations for the components.
//

class EquationComponent1
  record R
    Real x,y;
  end R;
  R a,b;
equation
  a = b;
end EquationComponent1;

// Result:
// function EquationComponent1.R "Automatically generated record constructor for EquationComponent1.R"
//   input Real x;
//   input Real y;
//   output R res;
// end EquationComponent1.R;
//
// class EquationComponent1
//   Real a.x;
//   Real a.y;
//   Real b.x;
//   Real b.y;
// equation
//   a = b;
// end EquationComponent1;
// [flattening/modelica/equations/EquationComponent1.mo:13:3-13:8:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationComponent1.mo:15:3-15:8:writable] Warning: Equation sections are deprecated in class.
//
// endResult
