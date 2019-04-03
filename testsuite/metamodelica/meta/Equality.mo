package Equality
  constant Integer iConst = 4;

  function twoIdent
    input Integer i1;
    input Integer i2;
    output Integer o1;
    output Integer o2;
  algorithm
    o1 := i1;
    o2 := i2;
  end twoIdent;

  function myEquality
    input Integer x;
    output Integer out;
  algorithm
    out := matchcontinue (x)
      local
        Integer i;
      case 1
        equation
          equality(1 = 1);
        then 1;
      case 2
        equation
          equality(1 = 2);
        then -1;
      case 2 then 2;
      case 3
        equation
          equality(1::{2} = {1,2});
        then 3;
      case 4
        equation
          i = 1;
          equality(i::{2} = {1,2});
        then 4;
      case _
        then 0;
    end matchcontinue;
  end myEquality;
end Equality;

model M
  Integer i = Equality.myEquality(realInt(time));
end M;
