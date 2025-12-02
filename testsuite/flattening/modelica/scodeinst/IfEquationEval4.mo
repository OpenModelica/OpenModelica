// name: IfEquationEval4
// keywords:
// status: correct
//

model IfEquationEval4
  parameter Boolean b[2] = {true, false};
  Real x[3];
equation
  for i in 1:3 loop
    if i == 1 then
      if b[i + 1] == false then
        x[i] = 0;
      else
        x[i] = 1;
      end if;
    else
      x[i] = 2;
    end if;
  end for;
end IfEquationEval4;

// Result:
// class IfEquationEval4
//   final parameter Boolean b[1] = true;
//   final parameter Boolean b[2] = false;
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x[1] = 0.0;
//   x[2] = 2.0;
//   x[3] = 2.0;
// end IfEquationEval4;
// endResult
