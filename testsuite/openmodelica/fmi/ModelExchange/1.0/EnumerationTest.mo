type Enum = enumeration(
    test1,
    test2,
    test3);

model EnumerationTest
  parameter Enum s = Enum.test2;
  Real x(start = 1);
  parameter Real a = 1;
equation
  der(x) = - a * x;
end EnumerationTest;
