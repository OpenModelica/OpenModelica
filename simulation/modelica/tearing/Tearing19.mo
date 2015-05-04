model Tearing19
   Real x0(start=0.2);
   Real x1(start=3.0);
   Real x2(start=-1.5);
   Real x3(start=3.6);
   Real x4(start=-2.5);
   Real x5(start=-2.1);
equation
   -min(abs(x0),1/2)  = sin(x1); // x1 = f(x0);
   min(abs(x0),1/2) = cos(x2); // x2 = f(x0);
   x1^2 + x2^2 = x3^2; // x3 = f(x1,x2)
   x0^3 + x4 + x3 = 1.0; // x4 = f(x0,x3)
   x5^5 + x4^4 + x0*x1*x2 = 1;
   0.0 = log(x0+x1 + x2 + x3 + x4 + x5+ time^2); // res
end Tearing19;

