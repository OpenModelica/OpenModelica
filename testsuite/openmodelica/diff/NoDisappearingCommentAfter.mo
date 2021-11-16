function CubicHermite
algorithm
  h := x2 - x1;
  if abs(h) > 0 then
    t := (x - x1) / h;
  else
    y := (y1 + y2) / 2;
  end if;
// Regular case
// Degenerate case, x1 and x2 are identical, return step function
  annotation(
    smoothOrder = 3);
end CubicHermite;
