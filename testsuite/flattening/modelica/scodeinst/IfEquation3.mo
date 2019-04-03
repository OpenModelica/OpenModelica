// name: IfEquation3
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquation3
  type E = enumeration(one, two, three);
  parameter E e = E.one;
  Real x = 1.0;
equation
  if e == E.one then
    x = 2.0;
  end if;
end IfEquation3;

// Result:
// class IfEquation3
//   parameter enumeration(one, two, three) e = E.one;
//   Real x = 1.0;
// equation
//   x = 2.0;
// end IfEquation3;
// endResult
