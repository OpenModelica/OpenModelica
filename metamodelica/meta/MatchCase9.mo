// High-level MetaModelica data structures
// Some language ambiguities with tuples and lists/arrays need
// to be solved.
model MatchCase9

  type MyType1 = Option<list<tuple<Integer,Integer>>>;
  type MyType2 = Option<tuple<tuple<MyType1,Integer>,tuple<Integer,Boolean>,Option<Boolean>>>;
  type MyType3 = list<list<Integer>>;
  type MyType4 = list<MyType1>;

  function func
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
  end func;

  Integer i;
equation
  i = func(1);
end MatchCase9;
