package Algorithms
/*
  This files contains a couple of different algorithms; no match or matchcontinue expressions.
*/

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

function fibonacci
  input output Integer N;
algorithm
  N := if N < 2 then N else fibonacci(N-1) + fibonacci(N-2);
end fibonacci;

function factorial
  input Integer N;
  output Integer NO;
algorithm
  NO := if N < 0 then 1 else N * factorial(N - 1);
end factorial;

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
