// name: IfEquationEval3
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquationEval3
  Real x;
equation
  if time < 1 then
    x = 0;
  elseif true then
    x = 1;
  else
    x = 2;
  end if;
end IfEquationEval3;

// Result:
// class IfEquationEval3
//   Real x;
// equation
//   if time < 1.0 then
//     x = 0.0;
//   else
//     x = 1.0;
//   end if;
// end IfEquationEval3;
// endResult
