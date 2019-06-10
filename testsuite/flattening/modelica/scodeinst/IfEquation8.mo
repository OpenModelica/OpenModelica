// name: IfEquation8
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfEquation1
  parameter Boolean b;
  Real x;
equation
  if b == true then
    x = 1;
  else
    x = 2;
  end if;
end IfEquation1;

// Result:
// class IfEquation1
//   parameter Boolean b;
//   Real x;
// equation
//   if b == true then
//     x = 1.0;
//   else
//     x = 2.0;
//   end if;
// end IfEquation1;
// endResult
