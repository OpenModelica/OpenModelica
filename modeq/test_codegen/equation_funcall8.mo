function test2
  input Integer n;
  input Real a[n];
  output Real b[n];
algorithm
  for i in 1:size(a,1) loop
    b[i] := a[i]*2;
  end for;
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
  parameter Real b[3]={1,2,3};
  Real x1=test(a);
  Real x2=test(size(b,1));
  Real x3=test(size(test2(size(b,1),b),1));
  Real y;
equation
  y = test(x1+x2);
end mo;

