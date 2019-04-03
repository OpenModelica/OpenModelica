package Shadowing1

  function test
    input Integer x;
    output Integer y;
  algorithm
    y := matchcontinue (x)
      local
        Integer y,z;
        Real x1;
      case _ then 42;
    end matchcontinue;
  end test;

end Shadowing1;
