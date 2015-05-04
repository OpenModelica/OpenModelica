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
//   parameter Boolean b = false;
//   Real x;
// equation
//   x = 2.0;
// end EquationIf2;
// endResult
