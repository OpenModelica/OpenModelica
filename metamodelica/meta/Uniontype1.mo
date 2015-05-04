uniontype UT
  record REC1
    Integer x;
  end REC1;

  record REC2
    Integer i;
    Real r;
    String s;
    Boolean b;
  end REC2;

  record REC3
    String x;
  end REC3;

  record REC4
    Boolean x;
  end REC4;
end UT;

model Uniontype1

    function test
      input Integer s;
      output Integer k;
    protected
      UT re;
    algorithm
      re := REC1(66);
      re := REC2(66,66.0,"66.0",true);
      re := REC2(i=66,r=66.0,s="66.0",b=true);
      k := 5;
    end test;

    Integer a;
  equation
    a = test(5);
end Uniontype1;
