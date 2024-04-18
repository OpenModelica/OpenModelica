package TestNonStandardExtensions

model TestEnumAsInteger

  type E = enumeration(one, two, three);
  constant Integer N = 3;
  Integer i[N];
  Real x;
equation
  i[E.one] = 1;
  i[E.two] = 2;
  i[E.three] = 3;
  x = if E.three > 1 then 1.0 else 2.0;
end TestEnumAsInteger;

model TestIntegerAsEnum

  type E = enumeration(one, two, three);
  constant Integer N = 3;
  Integer i[E];
  Integer x;

function f
  input E e;
  output Integer i;
algorithm
  i := Integer(e);
end f;

equation
  i[1] = 1;
  i[2] = 2;
  i[3] = 3;
  x = f(i[3]);
end TestIntegerAsEnum;


end TestNonStandardExtensions;