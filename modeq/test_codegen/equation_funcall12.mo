function test2
  input Real a[:];
  output Real b[size(a,1)+1];
algorithm
  for i in 1:size(a,1) loop
    b[i] := a[i]*2;
  end for;
  b[size(a,1)+1]:=size(a,1);
end test2;

function test3
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 7;
end test3;

function test
  input  Real x;
  output Real y;
protected
algorithm
  y := cos(x) + 4;
end test;

model mo
  parameter Real a=5;
  parameter Real b[3]={1,2,3};
  Real x1=test(a);
  Real x2=size(test2(b),1);
//  Real x3=test(size(test2(size(b,1),b),1));
  Real y;
  Real z;
equation
  y = test(x1+x2);
  z = test(test3(y));
end mo;

