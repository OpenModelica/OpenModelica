model Delay
  Real x;
  Real y;
  Real z;
  Real w;
equation
  x = delay(y+1, 2.5);
  y = if time < 5 then sin(time) else cos(time);
  z = delay(y, 0.01);
  w = delay(delay(y, 0.5), 1.5);
end Delay;
