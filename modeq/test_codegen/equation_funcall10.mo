function test2
  output Real x[4]:={1,2,3,4};
end test2;

function test3
  input Real a;
  output Real x := a+5;
end test2;

function test
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 4;
end test;

model mo
  parameter Real a=5;
  parameter Real b=sqrt(a);
  Real x1=test(a);
//  Real x3=test(size(test2(size(b,1),b),1));
  Real x3=test(test3(sin(x1)));
  Real y;
equation
  y = test(x1+x3);
end mo;

