within SiemensPower.Utilities.Functions;
function my_linspace

  input Real x1;
  input Real x2;
  input Integer n;
  output Real y[n];
algorithm
  if n>1 then
    for i in 1:n loop
      y[i]:=x1+(i-1)/(n-1)*(x2-x1);
    end for;
  else
    y[1]:=x1;
  end if;

end my_linspace;
