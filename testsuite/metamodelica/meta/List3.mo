model List3

  public
  type AList = list<String>;

  function func
    input Integer a;
    output Integer b;
  protected
    AList aList;
  algorithm
    b := 3;
    aList := {"string1","string2"};
    _ :=
    matchcontinue (aList)
      local
        String s,s1,s2;
        AList rest;
      case {s,_}
      then ();
      case {s1,s2}
        equation
        then ();
      case (s1 :: rest)
        equation
        then ();
    end matchcontinue;
  end func;

  Integer c;
equation
  c = func(1);
end List3;
