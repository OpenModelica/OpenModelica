// A simple integrator example.
//

model SimpleIntegrator
  Real u = 1.0;
  Real x(start = 2.0);
equation
  der(x) = u;
end SimpleIntegrator;
