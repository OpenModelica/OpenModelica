
function algorithm_if1

  input Real x;
  output Real y;

algorithm

  y := 1;
  if x < 3 then
    y := 4;
  end if;

  if y > 3 then
    y := 0 - y;
  elseif y > 2 then
    y := 2*y;
  else
    y := 2;
  end if;


end algorithm_if1;


model mo
end mo;
