package MatchCase6

  function func
    input String s;
    input Integer i;
    input Boolean b;
    output Integer x1;
    output Integer x2;
  algorithm
    (x1,x2) :=
    matchcontinue (s,i,b)
      case ("hej",1,false)
        then (1,2);
      case ("hej",1,_)
        then (3,4);
    end matchcontinue;
  end func;

end MatchCase6;
