

function BubbleSort
  input  Real[:] x;
  output Real[size(x,1)] y;
protected
  Integer j;
  Real t;
algorithm
  y := x;
  for i in 1:size(x,1) loop
    j := size(x,1);
    while j >= i + 1 loop
      if y[j] < y[j-1] then
        t := y[j];
        y[j] := y[j-1];
        y[j-1] := t;
      end if;
      j := j - 1;
    end while;
  end for;
end BubbleSort;
