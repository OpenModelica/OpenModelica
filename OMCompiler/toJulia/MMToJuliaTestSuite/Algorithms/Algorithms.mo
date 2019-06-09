package Algorithms

uniontype Complex
  record COMPLEX
    Real r;
    Real i;
  end COMPLEX;
end Complex;

function test
protected
  Complex a;
  Complex b;
  Complex c;
  array<Complex> nmbrs;
algorithm
  a := COMPLEX(5,6);
  b := COMPLEX(-3,4);
  c := COMPLEX(0,1.0*3.14159265358979323846);
  print(complexString(mul(a,b))+"\n");
  print(complexString(mul(b,a))+"\n");
  print(complexString(expC(c))+"\n");
end test;

function complexString
  input Complex cx;
  output String str;
algorithm
  if cx.i == 0 then
    str := realString(cx.r);
  elseif cx.r == 0 then
    str := realString(cx.i);
  elseif cx.i < 0 then
    str := realString(cx.r) + "-" + realString(cx.i * (-1.0)) + "i";
  else
    str := realString(cx.r) + "+" + realString(cx.i) + "i";
  end if;
end complexString;

function add input Complex a; input Complex b; output Complex c;
algorithm
  c := COMPLEX(a.r + b.r,a.i + b.i);
end add;

function sub
  input Complex a; input Complex b; output Complex c;
algorithm
  c := COMPLEX(a.r - b.r,a.i - b.i);
end sub;

function mul input Complex a; input Complex b; output Complex c;
algorithm
  c := COMPLEX(a.r * b.r - a.i * b.i, a.r * b.i + a.i * b.r);
end mul;

function expC
  input output Complex a;
algorithm
  a := COMPLEX(exp(a.r) * cos(a.i), exp(a.r) * sin(a.i));
end expC;

function createTestArray2
  input Integer siz;
  output list<Complex> complexNumbers;
protected
  array<Complex> A;
algorithm
  A := arrayCreate(siz,COMPLEX(0,0));
  complexNumbers := arrayList(A);
end createTestArray2;



function pivot1
  input Real b[:,:];
  input Integer p;
  input Integer q;
  output Real a[size(b,1),size(b,2)];
protected
  Integer M;
  Integer N;
algorithm
  a := b;
  N := size(a,1) - 1;
  M := size(a,2) - 1;
  for j in 0:N loop
    for k in 0:M loop
      if j<>p and k<>q then
        a[j+1,k+1] := a[j+1,k+1] - a[p+1,k+1]*a[j+1,q+1]/a[p+1,q+1];
      end if;
    end for;
  end for;
  for j in 0:N loop
    if j<>p then
      a[j+1,q+1] := 0;
    end if;
  end for;
  for k in 0:M loop
    if k<>q then
      a[p+1,k+1]:=a[p+1,k+1]/a[p+1,q+1];
    end if;
  end for;
  a[p+1,q+1] := 1;
end pivot1;

function simplex1
  input Real matr[:,:];
  output Real x[size(matr,2) -1];
  output Real z;
  output  Integer q;
  output  Integer p;
protected
  Real a[size(matr,1),size(matr,2)];
Integer M;
  Integer N;
algorithm
  N := size(a,1) - 1;
  M := size(a,2) - 1;
  a := matr;
  p:=0; q:=0;
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
end simplex1;

function split
  input array<Complex> A;
  input Integer start;
  input Integer stop;
protected
  array<Complex> tmp;
  Integer middle;
algorithm
  middle := intDiv(stop - start,2);
  tmp := arrayCreate(middle+1,COMPLEX(0,0));
  for i in 1:middle loop
    arrayUpdate(tmp,i,arrayGet(A,start + i * 2));
  end for;
  for i in 1:middle loop
    arrayUpdate(A,start + i,arrayGet(A,start + i * 2 - 1));
  end for;
  for i in 1:middle loop
    arrayUpdate(A,start + i + middle,arrayGet(tmp,i));
  end for;
end split;

function FFT
  input array<Complex> A;
  input Integer start;
  input Integer stop;
protected
  Complex oddElem;
  Complex expFactor;
  Complex evenElem;
  Real PI = acos(-1);
  Real factor;
  Integer middle;
algorithm
  middle := start + intDiv(stop-start,2);
  if stop - start == 1 then return;
  else
    split(A,start,stop);
    FFT(A=A,start=start,stop=middle);
    FFT(A=A,start=middle,stop=stop);
    for i in 1:intDiv(stop-start,2) loop
      factor := (-2.0 * PI * intReal(i - 1)) / intReal(stop-start);
      oddElem := arrayGet(A,start + i);
      evenElem := arrayGet(A,i + middle);
      expFactor := mul(expC(COMPLEX(0,factor)),evenElem);
      arrayUpdate(A,start + i,add(oddElem,expFactor));
      arrayUpdate(A,i + middle,sub(oddElem,expFactor));
    end for;
  end if;
end FFT;

function fib2
  input Integer i;
  output Integer o;
algorithm
  o := match i
	case 0 then 0;
    case 1 then 1;
    else then fib2(i - 1) + fib2(i - 2);
  end match;
end fib2;

function tak
  input Integer x;
  input Integer y;
  input Integer z;
  output Integer o;
algorithm
  o := if y < x then tak(tak(x-1, y, z), tak(y-1, z, x), tak(z-1, x, y))
	else z;
end tak;

function ackerman
  input Integer m;
  input Integer n;
  output Integer no;
algorithm
  if m == 0 then
	no := n + 1;
  elseif m > 0 and n == 0 then
	no := ackerman(m-1,1);
  elseif m > 0 and n > 0 then
	no := ackerman(m-1, ackerman(m,n-1));
  end if;
end ackerman;

function swap
  input Real a;
  input Real b;
  output Real ao;
  output Real bo;
algorithm
  ao := b;
  bo := a;
end swap;

function inSort
  input array<Real> arr;
protected
  Integer i = 1;
algorithm
  while i < arrayLength(arr) loop
    while j > 0 and arrayGet(arr,j-1) > arrayGet(arr,j) loop
      (i,j) := swap(arrayGet(arr,j),arrayGet(arr,j-1));
      j := j - 1;
    end while;
    i := i + 1;
  end while;
end inSort;

function realSummation
  output Real result;
protected
  Real r1;
  Real r2;
  Real r3;
  Real r4;
algorithm
  r1 := 0;
  r2 := 0;
  r3 := 0;
  r4 := 0;
  for i in 1:200 loop
	for j in 1:200 loop
	  for k in 1:200 loop
		r1 := r1 + i;
		r2 := r2 + i;
		r3 := r3 + i;
		r4 := r4 + i;
	  end for;
	end for;
  end for;
  result := r1+r2+r3+r4;
end realSummation;

end Algorithms;
