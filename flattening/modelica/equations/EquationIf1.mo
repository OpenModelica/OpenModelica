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
//   parameter Boolean b = true;
//   Real x;
// equation
//   x = 1.0;
// end EquationIf1;
// endResult
