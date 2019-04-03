package MatchCase7
  function func
    input Integer x;
    input Integer y;
    output Integer z;
  algorithm
    z :=
    matchcontinue (x,y)
      local
        Integer i;
        Integer r1,r2;
      case (i,r1)
        equation
          true = (i == 13);
        then i;
      case (_,23)
        equation

        then 5;
      case (_,r2 as _) then 9;
    end matchcontinue;
  end func;

end MatchCase7;
