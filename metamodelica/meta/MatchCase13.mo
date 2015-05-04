package MatchCase13

  function func1
    input Integer i;
    output tuple<Integer,Integer> b;
  algorithm
    b := match (i)
      case _ then (i*1,i*2);
    end match;
  end func1;

  function func2
    input Integer i1;
    input Integer i2;
    output tuple<Integer,Integer> b1;
    output tuple<Integer,Integer> b2;
  algorithm
    (b1,b2) := match (i1,i2)
      case (_,_) then (func1(i1),func1(i2));
    end match;
  end func2;

end MatchCase13;
