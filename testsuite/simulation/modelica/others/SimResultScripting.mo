class SimResultScripting

record R
  Real r;
end R;

constant R r1(r = 1.0);
Real r2 = r1.r;

end SimResultScripting;
