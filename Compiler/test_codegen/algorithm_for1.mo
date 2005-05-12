
function algorithm_for1

  input Integer n;
  output Real x;

  Real y[2,2];
algorithm

  x := 0.7;
  for i in 1:0.5:n loop
    x := x * x;
  end for;

  for i in y loop
    x := x*x;
  end for;

end algorithm_for1;

model mo
end mo;
