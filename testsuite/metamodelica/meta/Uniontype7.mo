// name:     Uniontype7
// keywords: Uniontype
// status:   correct
// cflags:   +g=MetaModelica
//
// Uniontype Testing
//

package Uniontype7
  record foo
      Integer i;
      Real r;
      String s;
      Boolean b;
  end foo;

  uniontype UT
    record REC1
      foo y;
      Integer x;
    end REC1;

    record REC2
      Real z;
    end REC2;
  end UT;

  function test
    input Integer s;
    output Integer k;
  protected
    UT re;
    foo f;
  algorithm
    f := foo(1,1.0,"1.0",false);
    re := REC1(f,1);
    re := REC1(foo(2,2.0,"2.0",true),2);
    k := 5;
  end test;
end Uniontype7;
