// name:     EquationIf4
// keywords: equation
// status:   correct
//
// Testing `if' clauses in equations.
// The condition may be a non-parameter expresion if all
// branches have the same number of equations.

class EquationIf4
  Real p = 10*time;
  Real x;
equation
  if p<0.0 then
    x = 1.0;
  elseif p<10.0 then
    x = 2.0;
  elseif p > 10.0 then
    x = 3.0;
  else
    x = 4.0;
  end if;
end EquationIf4;

// Result:
// class EquationIf4
//   Real p = 10.0 * time;
//   Real x;
// equation
//   if p < 0.0 then
//   x = 1.0;
//   elseif p < 10.0 then
//   x = 2.0;
//   elseif p > 10.0 then
//   x = 3.0;
//   else
//   x = 4.0;
//   end if;
// end EquationIf4;
// endResult
