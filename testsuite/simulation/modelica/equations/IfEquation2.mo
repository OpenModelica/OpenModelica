// name:     IfEquation2
// keywords: if
// status:   correct
//
// Drmodelica: 8.2 Conditional Equations with if-Equations (p. 245)
//

model IfEquation2
 Real x;
 Real y(start=1);
 Real z;
 parameter Real a = 20;
equation
  der(x) = y * z;
  der(y) = a * z;
  if x > y then
    z = a * x / y + x * (y - a) ^ 2.0;
  elseif y < z then
    z = a * x / y + x * (a - x) ^ 2.0;
  elseif y < z then
    z = a * x / y + x * (a - x) ^ 2.0;
  elseif y < z then
    z = a * x / y + x * (a - x) ^ 2.0;
  elseif y < z then
    z = a * x / y + x * (a - x) ^ 2.0;
  elseif y < z then
    z = a * x / y + x * (a - x) ^ 2.0;
  elseif y < z then
    z = a * x / y + x * (a - x) ^ 2.0;
  elseif y < z then
    z = a * x / y + x * (a - x) ^ 2.0;
  elseif y < z then
    z = a * x / y + x * (a - x) ^ 2.0;
  // We really only check if we can transform any number of equations
  else
    z = a * x / y;
  end if;
end IfEquation2;
