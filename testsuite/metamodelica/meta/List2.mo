model List2

  function func
    input Integer i;
    output Integer x1;
  protected
    list<Integer> listInt1;
    list<Integer> listInt2;
    Integer b;
  algorithm
    listInt1 := {1,2,3,4,5};
    listInt2 := {};
    b :=
    matchcontinue(listInt1,listInt2)
      local
        list<Integer> listInt3;
      case (1 :: listInt3,{})
        then 1;
      case (2 :: _,{})
        then 2;
      case (3 :: listInt3,{})
        then 3;
    end matchcontinue;
    x1 := 1;
  end func;

  Integer a;
equation
  a = func(5);
end List2;
