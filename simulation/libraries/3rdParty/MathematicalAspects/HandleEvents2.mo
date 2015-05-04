model HandleEvents2
  constant Real pi = Modelica.Constants.pi;
  parameter Real a = 2.3;
  Real u;
  Real y;
  Boolean flag(start = false);
equation
  u = sin(a * time);
  when sample(pi, pi) then
      flag = not pre(flag);

  end when;
  y = if flag then -1 else 1;
end HandleEvents2;

