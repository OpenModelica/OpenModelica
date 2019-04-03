model tearingSelect
   Real u0;
   Real i1 annotation(tearingSelect=prefer);
   Real i2 (start=1);
   Real i3;
   Real u1;
   Real u2 (start=1) annotation(tearingSelect=avoid);
   Real u3;
   parameter Real r1=10;
   parameter Real r2=10;
   parameter Real r3=10;
equation
   u0 = sin(time)*10;
   u1-r1*i1=0;
   u2-r2*i2=0;
   u3-r3*i3=0;
   u1+u3=u0;
   u2-u3=0;
   i1-i2-i3=0;
end tearingSelect;