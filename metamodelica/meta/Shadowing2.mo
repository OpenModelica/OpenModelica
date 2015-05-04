package Shadowing2

  function test
    input Integer x;
    output Integer y;
  algorithm
    y := matchcontinue (x)
      local
        Integer x,z;
        Real x1;
      case _ then 42;
    end matchcontinue;
  end test;

end Shadowing2;
