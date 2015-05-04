function tempInterpol1 "temporary routine for linear interpolation (will be removed)"
  input Real u "input value (first column of table)";
  input Real table[:,:] "table to be interpolated";
  input Integer icol "column of table to be interpolated";
  output Real y "interpolated input value (icol column of table)";
protected
  Integer i;
  Integer n "number of rows of table";
  Real u1;
  Real u2;
  Real y1;
  Real y2;
algorithm
  n:=size(table, 1);
  if n <= 1 then
    y:=table[1,icol];

  else   if u <= table[1,1] then
     i:=1;

   else   i:=2;
     while (i < n and u >= table[i,1]) loop
       i:=i + 1;

     end while;
     i:=i - 1;
   end if;
   u1:=table[i,1];
   u2:=table[i + 1,1];
   y1:=table[i,icol];
   y2:=table[i + 1,icol];
   assert(u2 > u1, "Table index must be increasing");
   y:=y1 + ((y2 - y1)*(u - u1))/(u2 - u1);
       end if;
end tempInterpol1;

model Interpol2Test
 Real x,y,z;
 Real x2,y2,z2;
  parameter Real table[:,:]=[0, 1,10; 1, 20,200; 2, 50,500;3,70,700]; //[0,2;1,3;2,4];

equation
  x = tempInterpol1(0.5,table,2);
  y = tempInterpol1(1.5,table,2);
  z = tempInterpol1(2.5,table,2);

  x2 = tempInterpol1(0.5,table,3);
  y2 = tempInterpol1(1.5,table,3);
  z2 = tempInterpol1(2.5,table,3);
end Interpol2Test;