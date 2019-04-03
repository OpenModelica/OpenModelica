function avg
  input Real x[:];
  output Real y;
algorithm
  y := 0;
  for i in x loop
    y := y + i;
  end for;
  y := y / size(x,1);
end avg;
model avgtest
  parameter Real eight=8;
  Real x=avg({1,2,3,4,eight});
end avgtest;
