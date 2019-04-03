// name: IfEquation7
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquation7
  Real x;
  Real y;
equation
  if time > 1 then
    x = 1.0;
    y = 2.0;
  elseif time > 2 then
    x = 2.0;
    y = 3.0;
  else
    x = 3.0;
    y = 4.0;
  end if;
end IfEquation7;

// Result:
// class IfEquation7
//   Real x;
//   Real y;
// equation
//   if time > 1.0 then
//     x = 1.0;
//     y = 2.0;
//   elseif time > 2.0 then
//     x = 2.0;
//     y = 3.0;
//   else
//     x = 3.0;
//     y = 4.0;
//   end if;
// end IfEquation7;
// endResult
