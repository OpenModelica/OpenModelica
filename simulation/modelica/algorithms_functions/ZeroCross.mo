model ZeroCrossAlg
 parameter Integer n = 8;
 Real a[n]={0.1,0.3,0.5,0.7,0.2,0.4,0.6,0.8},b[n];
 Real z;
algorithm
 z := sin(time);
 for i in 1:n loop
   if a[i] > time and z>0 then
      b[i] := 1;
   else
      b[i] := 0;
   end if;
 end for;
end ZeroCrossAlg;
