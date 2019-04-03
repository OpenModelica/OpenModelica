package Uniontype15

encapsulated package T1
  uniontype U
    record R
      Integer i;
    end R;
  end U;

  function func
    output U u;
  algorithm
    u := R(1);
  end func;


end T1;

encapsulated package T2

  import Uniontype15.T1;
  type U = T1.U;

  function func
    output U u;
  protected
    T1.U u1;
  algorithm
    u1 := T1.R(2);
    u := u1;
  end func;

end T2;

end Uniontype15;
