model testDummyDerMatching
  Real x(start=1),y(start=0);
  Real xd,yd;
  Real Foo;
equation
  x*x+y*y=1;
  der(y)=yd+sin(time);
  der(x)=xd+sin(time);
  der(xd) = -x*Foo;
  der(yd) = -Foo*y;
end testDummyDerMatching;

