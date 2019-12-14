package Algorithms
/*
  This files contains a couple of different algorithms; no match or matchcontinue expressions.
*/

import MetaModelica.Dangerous;

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

function splitFFT
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
end splitFFT;

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
    splitFFT(A, start, stop);
    FFT(A, start, middle);
    FFT(A, middle, stop);
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

public function append_reverse<T>
  "Appends the elements from list1 in reverse order to list2."
  input list<T> inList1;
  input list<T> inList2;
  output list<T> outList=inList2;
algorithm
  for e in inList1 loop
    outList := e::outList;
  end for;
end append_reverse;

protected function merge<T>
  "Helper function to sort, merges two sorted lists."
  input list<T> inLeft;
  input list<T> inRight;
  input CompareFunc inCompFunc;
  input list<T> acc;
  output list<T> outList;
  partial function CompareFunc
    input T inElement1;
    input T inElement2;
    output Boolean outRes;
  end CompareFunc;
algorithm
  outList := match (inLeft, inRight)
    local
      Boolean b;
      T l, r, el;
      list<T> l_rest, r_rest, res;
    /* Tail recursive version */
    case (l :: l_rest, r :: r_rest)
      algorithm
        if inCompFunc(r, l) then
          r_rest := inRight;
          el := l;
        else
          l_rest := inLeft;
          el := r;
        end if;
      then
        merge(l_rest, r_rest, inCompFunc, el :: acc);
    case ({}, {}) then listReverse(acc);
    case ({}, _) then append_reverse(acc,inRight);
    case (_, {}) then append_reverse(acc,inLeft);
  end match;
end merge;

function callFFT
  output list<Complex> oLst;
protected
  array<Complex> A;
algorithm
  A := listArray(createTestArray2(8));
  FFT(A, 0, 8);
  oLst := arrayList(A);
end callFFT;

function sort<T>
  "The merge sort algorithm from the compiler.
   Sorts a list given an ordering function with the mergesort algorithm.
    Example:
      sort({2, 1, 3}, intGt) => {1, 2, 3}
      sort({2, 1, 3}, intLt) => {3, 2, 1}"
  input list<T> inList;
  input CompareFunc inCompFunc;
  output list<T> outList= {};

  partial function CompareFunc
    input T inElement1;
    input T inElement2;
    output Boolean inRes;
  end CompareFunc;
protected
  list<T> rest = inList;
  T e1, e2;
  list<T> left, right;
  Integer middle;
algorithm
  if not listEmpty(rest) then
    e1 :: rest := rest;
    if listEmpty(rest) then
      outList := inList;
    else
      e2 :: rest := rest;
      if listEmpty(rest) then
        outList := if inCompFunc(e2, e1) then inList else {e2,e1};
      else
        middle := intDiv(listLength(inList), 2);
        (left, right) := splitLST(inList, middle);
        left := sort(left, inCompFunc);
        right := sort(right, inCompFunc);
        outList := merge(left, right, inCompFunc, {});
      end if;
    end if;
  end if;
end sort;

public function splitLST<T>
  "Takes a list and a position, and splits the list at the position given.
    Example: split({1, 2, 5, 7}, 2) => ({1, 2}, {5, 7})"
  input list<T> inList;
  input Integer inPosition;
  output list<T> outList1;
  output list<T> outList2;
protected
  Integer pos;
  list<T> l1 = {}, l2 = inList;
  T e;
algorithm
  true := inPosition >= 0;
  pos := inPosition;

  // Move elements from l2 to l1 until we reach the split position.
  for i in 1:pos loop
    e :: l2 := l2;
    l1 := e :: l1;
  end for;

  outList1 := Dangerous.listReverseInPlace(l1);
  outList2 := l2;
end splitLST;

end Algorithms;
