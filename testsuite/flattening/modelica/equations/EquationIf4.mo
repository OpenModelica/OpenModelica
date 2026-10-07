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
//     x = 1.0;
//   elseif p < 10.0 then
//     x = 2.0;
//   elseif p > 10.0 then
//     x = 3.0;
//   else
//     x = 4.0;
//   end if;
// end EquationIf4;
// [flattening/modelica/equations/EquationIf4.mo:10:3-10:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationIf4.mo:11:3-11:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationIf4.mo:13:3-21:9:writable] Warning: Equation sections are deprecated in class.
//
// endResult
