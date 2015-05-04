// name:     WhenVectorPredicateEquation
// keywords: when
// status:   correct
//
// Conditional Equations with when-equations
//

class WhenSet
  Real x;
  parameter Real y2 = 3;
  discrete Real y1;
  discrete Real y3;
equation
  x = time - y2;
  when {x > 2, sample(0, 2), x < 5} then
    y1 = sin(x);
    y3 = 2*x + y1 + y2;
  end when;
end WhenSet;

// Result:
// class WhenSet
//   Real x;
//   parameter Real y2 = 3.0;
//   discrete Real y1;
//   discrete Real y3;
// equation
//   x = time - y2;
//   when {x > 2.0, sample(0.0, 2.0), x < 5.0} then
//   y1 = sin(x);
//   y3 = 2.0 * x + y1 + y2;
//   end when;
// end WhenSet;
// endResult
