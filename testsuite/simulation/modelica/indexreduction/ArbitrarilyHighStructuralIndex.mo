within ;
model ArbitrarilyHighStructuralIndex
  Real v1;
  Real v3;
  Real i;
  parameter Real C=1;
  parameter Real R=1;
equation
  C * der(v1)  - C * der(v3) - i        = 0;
  -C * der(v1) + C * der(v3) + (1/R)*v3 = 0;
                             -i         = sin(time);

  annotation (uses(Modelica(version="3.2")));
end ArbitrarilyHighStructuralIndex;
