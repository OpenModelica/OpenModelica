within ;
model Delta
    Real x;
    parameter Real a=1;
equation
    x = 2*time*a;
  annotation (uses(Modelica(version="4.1.0")));
end Delta;
