function foo
  input Real x[:];
  output Real y[size(x,1)];
algorithm
  y:=x*2;
end foo;

model val
  Real x[3],y(start=1),z;
equation
  der(y)=-4*y;
  x=foo({y,2.,1.});
  z = x[1];
end val;
