// name: IfEquation8
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquation8
  parameter Boolean b(fixed = false);
  Real x;
initial equation
  b = true;
equation
  if b == true then
    x = 1;
  else
    x = 2;
  end if;
end IfEquation8;

// Result:
// class IfEquation8
//   parameter Boolean b(fixed = false);
//   Real x;
// initial equation
//   b = true;
// equation
//   if b == true then
//     x = 1.0;
//   else
//     x = 2.0;
//   end if;
// end IfEquation8;
// endResult
