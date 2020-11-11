// name:     WhenVectorPredicateEquation
// keywords: when
// status:   correct
//
// Conditional Equations with when-equations
//
// Drmodelica: 8.2 Conditional Equations with when-Equations (p. 246)
// cflags: -d=-newInst
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

// class WhenSet
// Real x;
// parameter Real y2 = 3;
// discrete Real y1;
// discrete Real y3;
// equation
//  x = time - y2;
//  when {x > 2.0,sample(0,2),x < 5.0} then
//  y1 = sin(x);
//  y3 = 2.0 * x + y1 + y2;
//  end when;
// end WhenSet;
