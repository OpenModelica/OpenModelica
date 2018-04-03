// name: IfEquation2
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquation2
  Real x;
  Boolean b;
equation
  if b then
    x = 1.0;
  else
    x = 2.0;
  end if;
end IfEquation2;

// Result:
// class IfEquation2
//   Real x;
//   Boolean b;
// equation
//   if b then
//     x = 1.0;
//   else
//     x = 2.0;
//   end if;
// end IfEquation2;
// endResult
