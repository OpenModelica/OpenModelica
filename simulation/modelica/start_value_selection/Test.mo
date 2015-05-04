

package Package

  type SomeStart = Real(start = 0);

  model Test
    SomeStart x(start = 20);
    replaceable type Y = SomeStart(start = 10);
    Y y(start = 15);
    Y z;
  equation
    x = y + z;
  end Test;

  model TestMore
    Test t;
    Test tredeclared(redeclare type Y = SomeStart(start = 10000));
  end TestMore;

  end Package;

