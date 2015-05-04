// name:     PartialFn9
// keywords: PartialFn
// status:  correct
//
// Using function pointers.
//
package PartialFn9

partial function testFunc
  input Integer x;
  output Integer y;
end testFunc;

function testFunc2
  extends testFunc;
  input Integer z;
  input Integer arg2;
  Integer foo = 5;
algorithm
  y := x + z + foo - arg2;
end testFunc2;

function testFunc3
  extends testFunc;
  input Integer inInt;
  input Integer arg3;
  input Integer arg4;
algorithm
  y := x + inInt + arg3 - arg4;
end testFunc3;

function testTestFunc
  input Integer a;
  input testFunc f;
  output Integer b;
algorithm
  b := matchcontinue (a)
    local
      Integer res;
    case(4)
      equation
        res = a + testTestFunc(a - 1,f = f);
      then
        res;
    case(_)
      equation
        res = f(a);
      then
        res;
  end matchcontinue;
end testTestFunc;

function runTest
  input Integer c;
  output Integer e;
  Integer d;
algorithm
  d := testTestFunc(c,function testFunc2(0,arg2=0));
  e := testTestFunc(d,function testFunc3(0,arg3=1,arg4=0));
end runTest;

end PartialFn9;
