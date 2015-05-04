package Uniontype14

  uniontype Exp
    record INT
      Integer int;
    end INT;
    record CALL
      list<Exp> args;
    end CALL;
  end Exp;

  function func
    input Exp e;
    input Integer i;
    output Exp call;
  algorithm
    call := CALL({e,INT(i)});
  end func;

end Uniontype14;
