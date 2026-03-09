model Example
  parameter Integer N = 3;
  Real v, w, y, z;
  Real x[N];
  Real a, b, c;

equation
  if v > 1.5 then
    w = v^2;
  else
    w = 0.5;
  end if;

  y + 3 * z + cos(time) = 0;
  z + y / 4 + v = 0;

  der(v) = y - 0.1 * v;

  for i in 1:N loop
    x[i] = i * w * v;
  end for;

algorithm
  a := v * 2.0;
  b := y + z;
  c := x[N] + a;
end Example;
