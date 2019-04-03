package MatchCase12

  function func
    input Integer i;
    output Integer b;
  algorithm
    b := match (i)
      case (1) then fail();
      case (_) then 2;
    end match;
  end func;

end MatchCase12;
