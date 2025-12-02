// name: IfEquationImpure1
// keywords:
// status: correct
//

model IfEquationImpure1
  Real x = time;
  Real y;
  parameter Boolean cond = false;
equation
  when Clock() then
    if sample(cond) then
      y = sample(x);
    else
      y = 0;
    end if;
  end when;
end IfEquationImpure1;

// Result:
// class IfEquationImpure1
//   Real x = time;
//   Real y;
//   parameter Boolean cond = false;
// equation
//   when Clock() then
//     if sample(cond, Clock()) then
//       y = sample(x, Clock());
//     else
//       y = 0.0;
//     end if;
//   end when;
// end IfEquationImpure1;
// endResult
