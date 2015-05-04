// name:     IfEquation3
// keywords: if
// status:   correct
//
// Checks that if-equations which have another if-equation in one of the branches are transformed correctly
//

model IfEquation3
 Real x;
 Real y;
equation
 if noEvent(time<1) then
  if noEvent(time>0.5) then
   x=0;
   y=1;
  else
   y=0;
   x=1;
  end if;
 elseif noEvent(time<1.5) then
  x=1;
  y=2;
 else
  y=1;
  x=2;
 end if;
end IfEquation3;
