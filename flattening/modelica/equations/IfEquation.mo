// name:     IfEquation
// keywords: if
// status:   correct
//
// Drmodelica: 8.2 Conditional Equations with if-Equations (p. 245)
//


class IfEquation
  parameter Real u;
  parameter Real uMax;
  parameter Real uMin;
  Real y;
equation
  if u > uMax then
    y = uMax;
  elseif u < uMin then
    y = uMin;
  else
    y = u;
  end if;
end IfEquation;

model Test
  IfEquation y1(u = 1.0, uMax = 2.0, uMin = 0.0);
  IfEquation y2(u = 0.0, uMax = 2.0, uMin = 0.0);
  IfEquation y3(u = 3.0, uMax = 2.0, uMin = 0.0);
end Test;

// Result:
// class Test
//   parameter Real y1.u = 1.0;
//   parameter Real y1.uMax = 2.0;
//   parameter Real y1.uMin = 0.0;
//   Real y1.y;
//   parameter Real y2.u = 0.0;
//   parameter Real y2.uMax = 2.0;
//   parameter Real y2.uMin = 0.0;
//   Real y2.y;
//   parameter Real y3.u = 3.0;
//   parameter Real y3.uMax = 2.0;
//   parameter Real y3.uMin = 0.0;
//   Real y3.y;
// equation
//   y1.y = y1.u;
//   y2.y = y2.u;
//   y3.y = y3.uMax;
// end Test;
// endResult
