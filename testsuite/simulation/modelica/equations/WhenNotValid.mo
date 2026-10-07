// name:     WhenNotValid
// keywords: when
// status:   incorrect
//
// Modelica restricts the equations allowed within a when-equation
// to a form where the result variable is on the left-hand side
//
// Drmodelica: 8.2 Conditional Equations with when-Equations (p. 246)
//
model WhenNotValid
  Real x, y;
equation
  x + y = 5;
  when sample(0, 2) then
    2*x + y = 7;                // Error: not valid Modelica code
  end when;
end WhenNotValid;

// class WhenNotValid
// Real x;
// Real y;
// equation
//   x + y = 5.0;
//   when sample(0,2) then
//   2.0 * x + y = 7.0;
//   end when;
// end WhenNotValid;
