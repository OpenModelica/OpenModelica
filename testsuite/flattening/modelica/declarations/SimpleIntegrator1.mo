// name:     SimpleIntegrator1
// keywords: declaration,equation
// status:   correct
//
// In this example 'x' is defined twice: constant and
// non-constant. The example is correct, but is not
// an integrator.

model SimpleIntegrator1
  Real u;
  Real x = 2.0;
equation
  der(x) = u;
end SimpleIntegrator1;


// Result:
// class SimpleIntegrator1
//   Real u;
//   Real x = 2.0;
// equation
//   der(x) = u;
// end SimpleIntegrator1;
// endResult
