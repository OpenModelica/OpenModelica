model Issue15901
  "Regression test for #15901: resolveLoops must not fold equations that
   contain array elements indexed by a non-constant subscript"
  Real u[2];
  Integer f(start = 1);
  Real y(start = 20), z(start = 0);
equation
  when time > 0.5 then
    f = 0;
  end when;
  u[1] = 10 + time;
  u[2] = 20 + time;
  // y and z form a 2x2 loop. The first equation indexes u by the
  // non-constant subscript f+1, so resolveLoops must stay away from it.
  y = u[f+1] - z;
  y = u[2] + z;
end Issue15901;
