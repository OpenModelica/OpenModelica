// name:     EquationIf3
// keywords: equation
// status:   correct
//
// Testing `if' clauses in equations.
//

class EquationIf3
  parameter Boolean b = false;
  Real x;
equation
  if b then
    x = 1.0;
  elseif not b then
    x = 2.0;
  else
    x = 3.0;
  end if;
end EquationIf3;

// Result:
// class EquationIf3
//   final parameter Boolean b = false;
//   Real x;
// equation
//   x = 2.0;
// end EquationIf3;
// [flattening/modelica/equations/EquationIf3.mo:9:3-9:30:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationIf3.mo:10:3-10:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationIf3.mo:12:3-18:9:writable] Warning: Equation sections are deprecated in class.
//
// endResult
