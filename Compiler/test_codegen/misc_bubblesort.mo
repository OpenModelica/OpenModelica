
function misc_bubblesort
  input Real[:] x;
  output Real[size(x,1)] y;
protected
  Real t;
algorithm

  y := x;

  for i in 1:size(x,1) loop
    for j in 1:size(x,1) loop

      if y[i] > y[j] then
	t := y[i];
	y[i] := y[j];
	y[j] := t;
      end if;
    end for;
  end for;

end misc_bubblesort;

model mo
  parameter Real a[8] = { 9,3,7,5,6,8,2,0 };
  Real b[8];
equation
  b=misc_bubblesort(a);
end mo;
