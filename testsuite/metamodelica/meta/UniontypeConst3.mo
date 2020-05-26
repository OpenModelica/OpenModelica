uniontype UT
  constant Real CONST1 = CONST2 * 3;
  constant Real CONST2 = CONST1 + 3;
  function f
    output Real ro;
  algorithm
    ro := CONST1 + CONST2;
  end f;
end UT;

function test
  output Real x;
algorithm
  x := UT.f();
end test;
