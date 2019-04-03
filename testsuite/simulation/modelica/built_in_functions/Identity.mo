class Identity
  parameter Integer d = 3;
  Real[d,d] x;
equation
  x = identity(d); // Must be evaluated during runtime
end Identity;
