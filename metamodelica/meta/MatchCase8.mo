package MatchCase8

  function func
    input String s;
    input Integer i;
    input Boolean b;
    output Integer x1;
    output Integer x2;
  algorithm
    (x1,x2) :=
    matchcontinue (s,i,b)
      local
        Integer x;
      case ("hej",1,false)
        equation
          fail();
        then (7,8);
      case ("hej",x as 1,_)
        equation
          false = (x == 1);
        then (3,4);
      case ("hejsan",1,false) then (5,6);
      case (_,_,_) then (7,8);
    end matchcontinue;
  end func;

end MatchCase8;
