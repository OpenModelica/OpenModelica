model MergingExample
  Real a;
  Real b;
  Real c;
  Real d;
  Real e;
  Real f;
  Real g;
  Real h;
  Real i;
  parameter Real x = 1;
equation
  a = x*time+sin(time);
  b = a*sin(time);
  c = b+time;
  d = a+cos(time);
  e = exp(d)*3;
  f = e+time;
  g = 5+f-time;
  h = 6*sin(g)*c;
  der(i) = h;
end MergingExample;
