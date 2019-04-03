model MatchCase5

  function func
    input String s;
    input Integer i;
    input Boolean b;
    output Integer x;
  algorithm
    x :=
    matchcontinue (s,i,b)
      local
        String s2;
        Integer i2;
      case ("hej",1,false) then 1;
      case ("socker",i2,_) then i2;
      case ("hej",1,false) equation then 3;
      case (_,1,true) then 4;
      case (s2,2,_) then 5;
    end matchcontinue;
  end func;

  Integer a;
equation
  a = func("hej",1,false);
end MatchCase5;