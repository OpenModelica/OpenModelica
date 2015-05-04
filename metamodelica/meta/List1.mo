model List1

  function func
    input Integer i;
    output Integer x1;
  protected
    list<Integer> listInt1;
    list<Integer> listInt2;
    list<list<Integer>> listInt3;
    list<Boolean> boolList1;
    list<list<Boolean>> boolList2;
    list<list<String>> stringList1;
    list<list<list<String>>> stringList2;
  algorithm
    listInt1 := {1,2,3,4};
    listInt2 := 1 :: listInt1;
    listInt2 := 1 :: listInt2;
    listInt1 := 1 :: {};
    listInt3 := {1,2,3,4} :: {};
    boolList1 := true :: {true,false};
    boolList2 := boolList1 :: {};
    stringList1 := {"jaha"} :: {{"hejsan","nej"}};
    stringList2 := stringList1 :: {};
    x1 := i;
  end func;

  Integer a;
equation
  a = func(5);
end List1;
