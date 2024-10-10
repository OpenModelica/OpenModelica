// name: IfEquation10
// keywords:
// status: correct
//

model IfEquation10
  parameter Real x[1] = ones(size(x, 1)) annotation(Evaluate=true);
  Real y;
equation
  if time > 1 then
    y = x[1] + x[2];
  else
    y = x[1];
  end if;
end IfEquation10;

// Result:
// class IfEquation10
//   final parameter Real x[1] = 1.0;
//   Real y;
// equation
//   if time > 1.0 then
//     y = 1.0 + x[2];
//   else
//     y = 1.0;
//   end if;
// end IfEquation10;
// endResult
