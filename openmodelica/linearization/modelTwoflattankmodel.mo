model twoflattankmodel
  Real h1(start=2);
  Real h2(start=1);
  Real F1;
  parameter Real A1=2,A2=0.5;
  parameter Real R1=2,R2=1;
  input Real F;
  output Real F2;
equation
  der(h1) = (F/A1) - (F1/A1);
  der(h2) = (F1/A2) - (F2/A2);
  F1 = R1 * sqrt(h1-h2);
  F2 = R2 * sqrt(h2);
end twoflattankmodel;
/*
model testtank
  Real x;
  Real y;
  twoflattankmodel a(F=x);
  Boolean switch(start=false);
equation
  y = a.F2;
  switch = a.h1 > 3;
  x = if edge(switch) then 0.5 else 5;
end testtank;

 */