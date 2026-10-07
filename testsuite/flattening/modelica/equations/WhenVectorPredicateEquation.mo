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
//     y1 = sin(x);
//     y3 = 2.0 * x + y1 + y2;
//   end when;
// end WhenSet;
// [flattening/modelica/equations/WhenVectorPredicateEquation.mo:9:3-9:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/WhenVectorPredicateEquation.mo:10:3-10:24:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/WhenVectorPredicateEquation.mo:11:3-11:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/WhenVectorPredicateEquation.mo:12:3-12:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/WhenVectorPredicateEquation.mo:14:3-14:16:writable] Warning: Equation sections are deprecated in class.
//
// endResult
