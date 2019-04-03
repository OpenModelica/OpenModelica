function foo
  input Real x[:];
  output Real y[size(x,1)];
algorithm
  y:=x*2;
end foo;

model ArrayEqn
  Real x[3],y(start=1);
equation
  der(y)=-4*y;
  x=foo({y,2.,1.});
end ArrayEqn;

model ArrayEqn1
  Real x[1],y(start=1);
equation
  der(y)=-4*y;
  x=foo({y,2.,1.});
end ArrayEqn1;

