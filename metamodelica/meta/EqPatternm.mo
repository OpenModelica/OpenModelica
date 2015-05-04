package EqPatternm

  function twoIdent
    input Integer i1;
    input Integer i2;
    output Integer o1;
    output Integer o2;
  algorithm
    o1 := i1;
    o2 := i2;
  end twoIdent;

  type myTup = tuple<Integer,Integer>;
  function twoTup
    input myTup i1;
    input myTup i2;
    output myTup o1;
    output myTup o2;
  algorithm
    o1 := i1;
    o2 := i2;
  end twoTup;

  uniontype UT
    record UT1
      Integer i;
    end UT1;
  end UT;

  function test
    input Integer x;
    output Integer y;
  algorithm
    y := matchcontinue (x)
      local
        Integer i;
        Real r;
        tuple<Integer,Real> tup;
        myTup a,b;
        UT ut;
        Boolean bool;
      case 1
        equation
          2 = 1+1;
        then 1;
      case 2
        equation
          2::{} = listRest({1,2});
        then 1;
      case 3
        equation
          tup = (1,1.0);
          (1,r) = tup;
          i = realInt(r);
        then i;
      case 4
        equation
          (1,r) = (1,1.0);
          i = realInt(r);
        then i;
      case 5
        equation
          (3,4) = twoIdent(3,4);
        then 1;
      case 6
        equation
          (a,b) = twoTup((3,4),(3,5));
        then 1;
      case 7
        equation
          ((3,4),b) = twoTup((3,4),(3,5));
        then 1;
      case 8
        equation
          ((3,4),(3,i)) = twoTup((3,4),(3,1));
        then i;
      case 9
        equation
          ut = UT1(1);
          UT1(i) = ut;
        then i;
      case 10
        equation
          true = x>=3;
        then 1;
      case 11
        equation
          x>=3 = true;
        then 1;
      case 12
        equation
          bool = true;  // Assignment
          bool = false; // Assignment
          false = bool; // Constraint
        then 1;
      case _
        then -1;
    end matchcontinue;
  end test;

end EqPatternm;
