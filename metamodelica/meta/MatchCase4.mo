model MatchCase4
  function func
    input String b;
    input Integer i;
    input Integer inta;
    output Integer x;
  algorithm
    x :=
    matchcontinue (b,i,inta)
      local
        String s2;
        Integer i2;
      case ("hej",1,3) then 1;
      case ("socker",1,4) then i2;
      case ("hej",1,6) then 3;
      case (_,1,8) then 4;
      case (s2,2,0) then 5;
    end matchcontinue;
  end func;

  Integer a;
equation
  a = func("hej",1,8);
end MatchCase4;