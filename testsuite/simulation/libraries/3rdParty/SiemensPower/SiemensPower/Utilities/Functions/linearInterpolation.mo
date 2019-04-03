within SiemensPower.Utilities.Functions;
function linearInterpolation "Linear flow characteristic"
  extends Modelica.Icons.Function;
  input Real x;
  input Real table[:, 2]
    "Table matrix (time = first column; e.g. table=[0, 0; 1, 1; 2, 4])";
  output Real y;

protected
  Real q[size(table, 1)];
  Real yi[size(table, 1)];
  Integer n;

algorithm
  n:=size(table, 1);
  for i in 2:n loop

   q[i]:=  min(1,max(0,(x-table[i-1,1])/(table[i,1]-table[i-1,1])));
   yi[i]:= (table[i,2]-table[i-1,2])*q[i];
  end for;

/*  if (n>1) then
    q[1]:=  min(0,(x-table[1,1])/(table[2,1]-table[1,1]));
    yi[1]:= (table[2,2]-table[1,2])*q[1]+table[1,2];
    q[n]:=  max(0,(x-table[n-1,1])/(table[n,1]-table[n-1,1]));
    yi[n]:= (table[n,2]-table[n-1,2])*q[n];
  else */
    q[1]:= 0;
    yi[1]:= table[1,2];
 // end if;

  y:=sum(yi);

end linearInterpolation;
