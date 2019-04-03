model Alg1 "model with an algorithm for one variable"
  Real x;
algorithm
  x:=1;
  x:=x+1;
end Alg1;

model Alg2 "model with an algorithm for two variables."
  Real x(start=1),y;
algorithm
  x:=1;
  y:=x+1;
end Alg2;

model Alg3 "model with mixed equation and algorithm sections"
  Real x, z, u;
  parameter Real w = 3, y = 2;
  Real x1, x2, x3;
equation
  x = y*2;
  z = w;
algorithm
  x1 := z  + x;
  x2 := y  - 5;
  x3 := x2 + y;
equation
  u = x1 + x2;
end Alg3;

model Alg4 "single algorithm with wrong causality"
  Real x,y;
equation
  der(x)=-x;
algorithm
  x:=y+1;
end Alg4;

model Alg5 "continues variables in algorithm"
  Real x1,x2,y1,y2,f,x3,x4;
function fak
 input Real n;
 output Real f;
algorithm
  f :=1;
  for i in 1:n loop
    f := f*i;
  end for;
end fak;
algorithm
  // approximation of sin(time)
  y1 := 0;
  for i in 0:5 loop
    f := fak(2*i+1);
    y1 := y1 + ((-1)^(i)/f)*time^(2*i+1);
  end for;
  y2 := sin(time);
  x4 := x3;
  x3 := x3+1+time;
equation
  der(x1) = y1;
  der(x2) = y2;
end Alg5;

/*
model Alg7
  Real x,y(start=1),z;
algorithm
  z := y;
  y := y + sin(time);
  der(x) := y;
end Alg7;
*/
