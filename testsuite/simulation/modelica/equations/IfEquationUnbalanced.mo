model IfEquationUnbalancedMissingElse
  Real x, y;
equation
  if x < 1.0 then
    x = time;
  elseif x >= 1.0 then
    x = 1.0;
    y = 2.0;
  end if;
end IfEquationUnbalancedMissingElse;

model IfEquationUnbalanced
  Real x, y;
equation
  if x < 1.0 then
    x = time;
  elseif x >= 1.0 then
    x = 1.0;
    y = 2.0;
  else
    x = 2 * time;
  end if;
end IfEquationUnbalanced;
