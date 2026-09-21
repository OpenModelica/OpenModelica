model TestOdeErrorRecovery
  "A model error at a DASSL trial point: recoverable, as C's IRES = -1"
  function bad
    input Real u;
    output Real y;
  algorithm
    assert(u < 0.5, "u out of range");
    y := u;
  end bad;
  Real x(start = 0.4, fixed = true);
equation
  der(x) = -bad(x + time);
end TestOdeErrorRecovery;
