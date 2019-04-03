
record foo
  Integer x;
  Real y;
  String z;
end foo;

uniontype UT
  record REC1
    Integer x;
    Real y;
    String z;
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
    UT ut;
  end REC4;

  record REC5
    foo f;
  end REC5;

  record REC6
    Integer i1;
    Integer i2;
    Integer i3;
    Integer i4;
    Integer i5;
  end REC6;
end UT;

package Uniontype8

function test
  input Integer s;
  output Integer k;
protected
  UT re;
algorithm
  re := REC1(66,2.5,"z");
  re := REC2(66,66.0,"66.0",true);
  re := REC2(i=66,r=66.0,s="66.0",b=true);
  re := test2(re);
  re := test3(1);
  k := s;
end test;

function test2
  input UT s;
  output UT u;
algorithm
  u := s;
end test2;

function test3
  input Integer s;
  output UT u;
algorithm
  u := REC1(s,s+1,"z");
end test3;

function test4
  input Integer s;
  output UT u;
algorithm
  u := REC4(REC1(1,2.5,"z"));
  u := REC4(u);
end test4;

function test5
  input Integer s;
  output UT u;
protected
  foo f;
algorithm
  f := foo(1,2.5,"z");
  u := REC5(f);
  u := REC4(REC4(u));
end test5;

function test6
  input Integer s;
  output UT u;
algorithm
  u := REC6(1,2,3,4,5);
  u := REC5(foo(1,2.5,"z"));
  u := REC4(REC4(u));
end test6;

end Uniontype8;
