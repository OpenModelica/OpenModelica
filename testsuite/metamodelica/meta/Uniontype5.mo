uniontype UT
  record REC1
    UT y;
  end REC1;

  record REC2
    Real z;
  end REC2;
end UT;

model Uniontype5

    function test
      input Integer s;
      output Integer k;
    protected
      UT re;
    algorithm
      re := REC2(1.5);
      re := REC1(re);
      re := REC1(re);
      re := REC1(re);
      re := REC1(re);
      k := 5;
    end test;

    Integer a;
  equation
    a = test(5);
end Uniontype5;
