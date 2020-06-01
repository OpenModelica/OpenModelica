uniontype UT
  record R
    Real RI;
  end R;
  function f
    output Real ro;
  protected
    UT tmpUT = R(1.0);
  algorithm
    ro := tmpUT.RI;
  end f;
  uniontype UT2
    record R1
    end R1;
   record R2
   end R2;
  end UT2;
end UT;

function test
  output Real x;
algorithm
  x := UT.f();
end test;
