
function pivot1
  input Real b[6,9];
  input Integer p;
  input Integer q;

  output Real a[6,9];

protected
  Integer M;
  Integer N;
  
algorithm
  
  a := b;
  N := size(a,1)-1;
  M := size(a,2)-1;

  for j in 0:N loop
    for k in 1:M+1 loop
      if j<>p and k<>q then
	a[j+1,k+1] := a[j+1,k+1]-a[p+1,k+1]*a[j+1,q+1]/a[p+1,q+1];
      end if;
    end for;
  end for;

  for j in 0:N loop
    if j<>p then
      a[j+1,q+1] := 0;
    end if;
  end for;
  
  for k in 1:M+1 loop
    if k<>q then
      a[p+1,k+1]:=a[p+1,k+1]/a[p+1,q+1];
    end if;
  end for;

  a[p+1,q+1] := 1;

end pivot1;

function misc_simplex1

  input Real matr[6,9];



  output Real x[8];
  output Real z;

  
protected
  Real a[6,9];
  Integer M;
  Integer N;
output  Integer q;
output  Integer p;

algorithm

  N := size(a,1)-1;
  M := size(a,2)-1;

  a := matr;

  p:=0;q:=0;
  while not (q==(M+1) or p==(N+1)) loop

    q := 0;
    while not (q == (M+1) or a[0+1,q+1]<0) loop
      q:=q+1;
    end while;

    p := 0;
    while not (p == (N+1) or a[p+1,q+1]>0) loop
      p:=p+1;
    end while;
    
    
    for i in p+1:N loop
      if a[i+1,q+1] > 0 then
	if (a[i+1,M+1]/a[i+1,q+1]) < (a[p+1,M+1]/a[p+1,q+1]) then
	  p := i;
	end if;
      end if;
    end for;

    
    if (q < M+1) and (p < N+1) then
      a := pivot1(a,p,q);
    end if;

  end while;

  for i in 1:M loop
    x[i] := -1;
    for j in 1:N+1 loop
      if (x[i] < 0) and ((a[j,i] >= 1.0) and (a[j,i] <= 1.0)) then
	x[i] := a[j,M+1];
      elseif ((a[j,i] < 0) or (a[j,i] > 0)) then
	x[i] := 0;	
      end if;
    end for;
  end for;

  z := a[1,M+1];

end misc_simplex1;

model mo
end mo;
