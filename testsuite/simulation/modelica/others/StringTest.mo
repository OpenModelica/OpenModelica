model STest1

   Real x=sin(time);
   Boolean b;
   Integer i=66;
equation
b = x < 0.2;
assert(x < 0.1,
 "x reached "+
 String(x,significantDigits=2)+
 " at time "+
 String(time,significantDigits=5)+
 " b ="+String(b)+
 " i = "+String(i,leftJustified=false,minimumLength=6));
end STest1;
