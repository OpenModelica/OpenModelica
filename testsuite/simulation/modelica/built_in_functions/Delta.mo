within ;
model Delta
    Real x;
    parameter Real a=1;
equation
    x = 2*time*a;
  annotation (uses(Modelica(version="3.2.1")));
end Delta;
