function foo
 input Real x;
 output Real y;
algorithm
 y:=14+x*2.0;
end foo;


model mo
  Real x;
  Real y(start=5);
equation
  der(y)=x;
  x=foo(sin(time));
end mo;
