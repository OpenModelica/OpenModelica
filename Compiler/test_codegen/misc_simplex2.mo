
function pivot2

  input Real b[:,:];
  input Integer p;
  input Integer q;

  output Real a[size(b,1),size(b,2)];

protected
  Real row[size(a,2)];
  Real col[size(a,1)];
  
algorithm
  
  row := b[p,:];
  col := b[:,q] * (1 / b[p,q]);

  for j in 1:size(b,1) loop

    a[j,:] := b[j,:] - (row * col[j]);
    a[j,q] := 0.0;

  end for;
  a[p,:] := row * (1 / b[p,q]);
  a[p,q] := 1.0;

end pivot2;

function misc_simplex2

  input Real matr[:,:];

  output Real x[size(matr,2)-1];
  output Real z;

  

  Real a[size(matr,1),size(matr,2)];
  Integer M;
  Integer N;
output  Integer q;
output  Integer p;

algorithm

  N := size(a,1);
  M := size(a,2);

  a := matr;

  p:=0;q:=0;
  while not (q==M or p==N) loop

    q := 1;
    while not (q == M or (a[1,q] < 0)) loop
      q:=q+1;
    end while;

    p := 1;
    while not (p == N or a[p,q] > 0) loop
      p:=p+1;
    end while;
    
    
    for i in p+1:N loop
      if a[i,q] > 0 then
	if (a[i,M]/a[i,q]) < (a[p,M]/a[p,q]) then
	  p := i;
	end if;
      end if;
    end for;

    
    if (q < M) and (p < N) then
      a := pivot2(a,p,q);

    end if;

  end while;

  for i in 1:M-1 loop
    x[i] := -1;
    for j in 1:N loop
      if (x[i] < 0) and ((a[j,i] >= 1.0) and (a[j,i] <= 1.0)) then
	x[i] := a[j,M];
      elseif ((a[j,i] < 0) or (a[j,i] > 0)) then
	x[i] := 0;	
      end if;
    end for;
  end for;

  
  z := a[1,M];

end misc_simplex2;

model mo
end mo;
