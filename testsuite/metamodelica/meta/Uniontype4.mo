uniontype UT
  record REC1
    Integer y;
  end REC1;

  record REC2
    Real z;
  end REC2;
end UT;

model Uniontype4

    function test
      input Integer s;
      output Integer k;
    protected
      UT re;
      Integer i;
      Real r;
    algorithm
      i := 1;
      r := 2.5;
      re := REC1(i);
      re := REC2(r);
      k := 5;
    end test;

    Integer a;
  equation
    a = test(5);
end Uniontype4;
