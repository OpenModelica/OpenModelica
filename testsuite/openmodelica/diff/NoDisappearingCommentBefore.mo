function CubicHermite
algorithm
  h := x2 - x1;
  if abs(h)>0 then
    // Regular case
    t := (x - x1)/h;
  else
    // Degenerate case, x1 and x2 are identical, return step function
    y := (y1 + y2)/2;
  end if;
  annotation(smoothOrder=3);
end CubicHermite;
