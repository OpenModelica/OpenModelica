
function algorithm_while1

  input Real x;
  output Real y;

algorithm

  y := 0;

  while (x < 6) loop
    
    y := y + x;
    x := x + 0.4;

  end while;

end algorithm_while1;


model mo
end mo;
