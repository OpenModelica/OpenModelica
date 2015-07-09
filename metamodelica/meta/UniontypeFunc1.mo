uniontype UT
  record R
    Real r;
  end R;

  function f
    input UT ut;
    output Real r;
  algorithm
    R(r = r) := ut;
  end f;
end UT;

function test
  output Real x;
protected
  UT ut = R(1.0);
algorithm
  x := UT.f(ut);
end test;
