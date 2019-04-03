// name: IfEquationEval1
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquationEval1
  Real x;
equation
  if true then
    x = 1;
  else
    x = 2;
  end if;
end IfEquationEval1;

// Result:
// class IfEquationEval1
//   Real x;
// equation
//   x = 1.0;
// end IfEquationEval1;
// endResult
