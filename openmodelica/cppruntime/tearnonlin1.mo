model tearnonlin1
  Real a(start=1),b(start=-1),c(start=1);
equation
  a + b + c=0;
  2*a - 3*b + 2*c=9;
  a*a + b*b + c*c=5;
end tearnonlin1;



