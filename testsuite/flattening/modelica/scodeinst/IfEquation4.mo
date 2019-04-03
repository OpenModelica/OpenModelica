// name: IfEquation4
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquation4
  type E = enumeration(one, two, three);
  parameter E e = E.one;
  Real x = 1.0;
equation
  if e <> E.one then
    x = 2.0;
  end if;
end IfEquation4;

// Result:
// class IfEquation4
//   parameter enumeration(one, two, three) e = E.one;
//   Real x = 1.0;
// end IfEquation4;
// endResult
