// name: IfEquation1
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquation1
  Real x;
equation
  if time > 1 then
    x = 1.0;
  else
    x = 2.0;
  end if;
end IfEquation1;

// Result:
// class IfEquation1
//   Real x;
// equation
//   if time > 1.0 then
//     x = 2.0;
//   else
//     x = 1.0;
//   end if;
// end IfEquation1;
// endResult
