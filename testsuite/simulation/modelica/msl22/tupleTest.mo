function foo
 input Real x;
 output Real y;
 output Real y2;
algorithm
  y:=x+1;
  y2:= x-1;
end foo;

model tplTest
 Real x,y;
 Real a;

equation
der(a)=-2*x;
(x,y) = foo(a);
end tplTest;

