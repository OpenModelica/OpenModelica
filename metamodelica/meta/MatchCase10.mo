model MatchCase10

  function func
    output Integer b;
  algorithm
    b := matchcontinue ()
      case () then 3;
    end matchcontinue;
  end func;

  Integer i;
equation
  i = func();
end MatchCase10;
