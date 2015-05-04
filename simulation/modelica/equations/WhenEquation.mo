// name:     WhenEquation
// keywords: when
// status:   correct
//
// Drmodelica: 8.2 Conditional Equations with when-Equations (p. 246)
//
model WhenEquation
  Real x(start = 1);
  discrete Real y1;
  parameter Real y2 = 3;
  discrete Real y3;
equation
  x = time - y2;
  when x > 2 then
    y1 = sin(x);
    y3 = 2*x + y1 + y2;
  end when;
end WhenEquation;

// class WhenEquation
// Real x(start = 1.0);
// discrete Real y1;
// parameter Real y2 = 3;
// discrete Real y3;
// equation
//   x = time - y2;
//   when x > 2.0 then
//   y1 = sin(x);
//   y3 = 2.0 * x + y1 + y2;
//   end when;
// end WhenEquation;