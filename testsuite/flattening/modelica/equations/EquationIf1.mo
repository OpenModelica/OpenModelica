// name:     EquationIf1
// keywords: equation
// status:   correct
//
// Testing `if' clauses in equations.
//

class EquationIf1
  parameter Boolean b = true;
  Real x;
equation
  if b then
    x = 1.0;
  else
    x = 2.0;
  end if;
end EquationIf1;

// Result:
// class EquationIf1
//   final parameter Boolean b = true;
//   Real x;
// equation
//   x = 1.0;
// end EquationIf1;
// [flattening/modelica/equations/EquationIf1.mo:9:3-9:29:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationIf1.mo:10:3-10:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationIf1.mo:12:3-16:9:writable] Warning: Equation sections are deprecated in class.
//
// endResult
