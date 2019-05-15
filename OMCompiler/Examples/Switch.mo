model Switch
  Real v;
  Real i;
  Real i1;
  Real itot;
  Boolean open;
equation
  itot = i + i1;
  if open then
    v = 0;
  else
    i = 0;
  end if;
   1 - i1 = 0;
   1 - v - i = 0;
   open = time >= 0.5;
end Switch;
