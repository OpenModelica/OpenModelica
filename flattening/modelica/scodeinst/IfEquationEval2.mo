// name: IfEquationEval2
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquationEval2
  Real x;
equation
  if false then
    x = 0;
  elseif true then
    x = 1;
  else
    x = 2;
  end if;
end IfEquationEval2;

// Result:
// class IfEquationEval2
//   Real x;
// equation
//   x = 1.0;
// end IfEquationEval2;
// endResult
