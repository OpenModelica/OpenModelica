function foo
 input Real x;
 output Real y;
algorithm
 y:=14+x*4.0;
end foo;


model mo
  Real x;
  Real y(start=5);
equation
  der(y)=x;
  x=sin(foo(time));
end mo;
