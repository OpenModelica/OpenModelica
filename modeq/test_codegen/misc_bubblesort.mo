
function misc_bubblesort
  input Real[10] x;
  output Real[10] y;
protected
  Real t;
algorithm

  y := x;

  for i in 1:size(x,1) loop
    for j in i:size(x,1) loop
      
      if y[i] > y[j] then
	t := y[i];
	y[i] := y[j];
	y[j] := t;
      end if; 
    end for;
  end for;

end misc_bubblesort;

model mo
end mo;
