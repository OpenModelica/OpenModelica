within ;


model functionTest3_elseif
  Real a;
  Real b;
  Real c;
  Real d;
  parameter Real x = 10;
equation

a = x * sin(time);
b = func2(-3.0,a);
c = b+a;
d = der(c);

  annotation (uses(Modelica(version="3.2")));
end functionTest3_elseif;
