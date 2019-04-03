model MatchCase3
  function func
    input String s;
    output Integer x;
  algorithm
    x :=
    matchcontinue (s)
      local
        String s2;
      case ("hej") then 1;
      case ("socker") then 2;
      case ("hej") then 3;
      case (_) then 4;
      case (s2) then 5;
    end matchcontinue;
  end func;

  Integer a;
equation
  a = func("hej");
end MatchCase3;