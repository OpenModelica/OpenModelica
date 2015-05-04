package Uniontype11

uniontype UT
  record REC1
    Integer x;
  end REC1;

  record REC2
    UT x;
  end REC2;
end UT;

function test
  input UT s;
  output UT u;
algorithm
  u := REC2(s);
end test;

end Uniontype11;
