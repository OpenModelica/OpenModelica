// name:     EquationIf2
// keywords: equation
// status:   correct
//
// Testing `if' clauses in equations.
// The branches need not have the same
// number of equations if the condition
// is a parameter-expression.

class EquationIf2
  parameter Boolean b = false;
  Real x;
equation
  if b then
    assert(true,"Should not happen");
  else
    x = 2.0;
  end if;
end EquationIf2;

// Result:
// class EquationIf2
//   final parameter Boolean b = false;
//   Real x;
// equation
//   x = 2.0;
// end EquationIf2;
// [flattening/modelica/equations/EquationIf2.mo:11:3-11:30:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationIf2.mo:12:3-12:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationIf2.mo:14:3-18:9:writable] Warning: Equation sections are deprecated in class.
//
// endResult
