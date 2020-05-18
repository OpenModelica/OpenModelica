uniontype UT
  constant Real R = 1.0;
  function f
    output Real r;
  algorithm
    r := R;
  end f;
end UT;

function test
  output Real x;
algorithm
  x := UT.f();
end test;
