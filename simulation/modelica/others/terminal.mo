model test111
  Real a(start = 0.1);
algorithm
 if terminal() then
    a := 1.0;
 end if;
 if initial() then
   a := 0.5;
 end if;
end test111;
