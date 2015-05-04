model MatchCase2
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
      case (i as 11,r1) then i;
      case (_,23) then 1;
      case (_,r2 as _) then r2;
    end matchcontinue;
  end func;

  Integer a;
equation
  a = func(13,12);
end MatchCase2;