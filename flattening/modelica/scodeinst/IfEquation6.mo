// name: IfEquation6
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquation6
  Real x;
equation
  if firstTick() then
    x = 0.0;
  end if;
end IfEquation6;

// Result:
// class IfEquation6
//   Real x;
// equation
//   if firstTick() then
//     x = 0.0;
//   end if;
// end IfEquation6;
// endResult
