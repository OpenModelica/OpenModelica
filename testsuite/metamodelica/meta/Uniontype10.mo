uniontype UT
  record REC1
    Integer x;
  end REC1;

  record REC2
    UT x;
  end REC2;

  record REC3
    foo f;
  end REC3;
end UT;

record foo
  Integer x;
end foo;

package Uniontype10

function test
  input UT s;
  output UT u;
algorithm
  u := REC2(s);
end test;

end Uniontype10;
