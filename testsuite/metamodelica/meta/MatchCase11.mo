package MatchCase11

  function func
    input Integer i;
    output Integer b;
  algorithm
    b := match (i)
      case (1) then fail();
    end match;
  end func;

end MatchCase11;
