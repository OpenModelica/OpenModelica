class Failure
  constant Integer iConst = 4;

  function twoIdent
    input Integer i1;
    input Integer i2;
    output Integer o1;
    output Integer o2;
  algorithm
    o1 := i1;
    o2 := i2;
  end twoIdent;

  function myFailure
    input Integer x;
    output Integer y;
  algorithm
    y := matchcontinue (x)
      local
        Integer i;
        Real r1;
      case 1
        equation
          failure(listGet({}, 1));
        then 1;
      case 2
        equation
          failure(i = listGet({1}, 2));
        then 1;
      case 3
        equation
          i = listGet({1}, 1);
        then 1;
      case 4
        equation
          failure((3,4) = twoIdent(3,5));
        then 1;
      case 5
        equation
          failure(equality(3 = 4));
        then 1;
      case _
        then -1;
    end matchcontinue;
  end myFailure;

  function myFailure2
    output Integer y;
  protected
    list<Integer> x;
  algorithm
    x := {1,2};
    y := matchcontinue (x)
      local
        Integer i;
        Real r1;
      case _
        equation
          failure({} = listRest(listRest(x)));
        then -1;
      case _ then 1;
    end matchcontinue;
  end myFailure2;
end Failure;
