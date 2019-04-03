package MatchCaseInteractive1

  function func
    input Integer x;
    input Boolean y;
    output Integer z;
  algorithm
    z :=
    matchcontinue (x,y)
      local
        Integer i;
      case (11,false) then 1;
      case (1222,false) then fail();
      case (i as 1222,false) then 2;
      case (i as _,_) then 4;
    end matchcontinue;
  end func;

  function stringFunc
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
  end stringFunc;

  public type AList = list<Integer>;

  function listFunc
    input AList aList;
    output String out;
  algorithm
    out := matchcontinue (aList)
      local
        Integer i,i1,i2;
        AList rest;
      case {} then "Empty list";
      case {1} then "{1}";
      case {1,2} then "{1,2}";
      case {i1,i2} then "{i1,i2}";
      case (1 :: 2 :: rest) then fail();
      case (1 :: 2 :: _) /*equation print("abc");*/ then "1::2::rest";
      case (2 :: 4 :: 6 :: {}) then "2::4::6::{}";
      case _ then "default";
    end matchcontinue;
  end listFunc;

  function listlistFunc
    input list<AList> aList;
    output String out;
  algorithm
    out := matchcontinue (aList)
      local
        Integer i,i1,i2;
        list<AList> rest;
      case {} then "Empty list";
      case {{1,2,3},{4,5,6}} then "{{1,2,3},{4,5,6}}";
      case {1,2,3} :: rest then "{1,2,3}::rest";
      case _ then "default";
    end matchcontinue;
  end listlistFunc;

  function simpleTupleFunc
    input tuple<Integer,Integer> tup;
    output Integer out;
  algorithm
    out := match (tup)
      local Integer i1,i2;
      case (i1,i2) then i1+i2;
    end match;
  end simpleTupleFunc;

  function tupleFunc "Tests unboxing of all data types"
    input tuple<Integer,Real,Boolean,String> tup;
    output Real out;
  algorithm
    out := matchcontinue (tup)
      case (2,1.0,true,"abc") then 1;
      case (1,2.0,true,"abc") then 2;
      case (1,1.0,false,"abc") then 3;
      case (1,1.0,true,"abcd") then 4;
      case (_,r,_,_) local Real r; then r;
      case _ then -1;
    end matchcontinue;
  end tupleFunc;

  type MyType1 = Option<list<tuple<Integer,Integer>>>;
  type MyType2 = Option<tuple<tuple<MyType1,Integer>,tuple<Integer,Boolean>,Option<Boolean>>>;
  type MyType3 = list<list<Integer>>;
  type MyType4 = list<MyType1>;

  function optionFunc
    input Integer a;
    output Integer b;
  protected
    MyType1 x1;
    MyType2 x2;
    MyType3 x3;
    MyType4 x4;
    list<list<MyType4>> x5;
  algorithm
    x1 := SOME({(a,a)});
    x2 := SOME(((NONE(),5),(5,true),SOME(true)));
    x3 := {1,2,3} :: {};
    x4 := {NONE(),NONE(),SOME({})};
    x5 := {x4 :: {x4,x4}};
    b :=
    matchcontinue (x1,x2,x3,x4,x5)
      local Integer i1,i2;
      case (SOME(_),SOME((_,_,NONE())),_,_,_) then 3;
      case (SOME({(i1,i2)}),SOME((_,_,SOME(_))),_,_,_) then i1+i2;
      case (NONE(),SOME(_),_,_,_) then 1;
    end matchcontinue;
  end optionFunc;

end MatchCaseInteractive1;
