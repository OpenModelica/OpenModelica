model linearmodel
 Real x1(start=1);
 Real x2(start=-2);
 Real x3(start=3);
 Real x4(start=-5);
 parameter Real a=3,b=2,c=5,d=7,e=1,f=4;
equation
  a*x1 =  b*x2 -der(x1);
  der(x2) + c*x3 + d*x1 = x4;
  f*x4 - e*x3 - der(x3) = x1;
  der(x4) = x1 + x2 + der(x3) + x4;
end linearmodel;
