

function if_algorithm

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


end if_algorithm;



model mo
end mo;
