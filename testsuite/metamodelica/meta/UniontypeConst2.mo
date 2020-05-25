uniontype UT
  constant UT CONST_UT = FOO(1.0);
  record FOO
    Real r;
  end FOO;
  function f
    output Real ro;
  algorithm
    FOO(r = ro) := CONST_UT;
  end f;
end UT;

function test
  output Real x;
algorithm
  x := UT.f();
end test;
