model MatchCase1

  function func
    input Integer x;
    input Boolean y;
    output Integer z;
  algorithm
    z :=
    matchcontinue (x,y)
      case (11,false) then 1;
      case (1222,false) then 2;
      case (1,true) then 4;
    end matchcontinue;
  end func;

  Integer a;
equation
  a = func(1222,false);
end MatchCase1;