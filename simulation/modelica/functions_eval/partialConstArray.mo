model partialConstArray
  Real x[2], y;
equation
  (x,y) = f(x[1]);
end partialConstArray;

function f
  input Real x1;
  output Real x[2];
  output Real y;
algorithm
  x[1] := 2;
  x[2] := x1 - 2;
  y := x[1] + x[2];
end f;