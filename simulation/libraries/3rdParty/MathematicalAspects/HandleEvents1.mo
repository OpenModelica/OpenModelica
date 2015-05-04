model HandleEvents1
  constant Real pi=Modelica.Constants.pi;
  Real u;
  Real y;
equation
  u = sin(time);
  y = if (sin(time)<0) then -1 else 1;
end HandleEvents1;
