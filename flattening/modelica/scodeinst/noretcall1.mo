// name: noretcall1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Expansion doesn't support nonret-calls yet.
//

package P
  function f1
    input Real x;
    input Real y;
  algorithm
    print(x);
    print(y);
  end f1;
end P;

function f2
  input Real x;
algorithm
  print(x);
end f2;

model A
  constant Real x = 2.0, y = 3.0;
equation
  P.f1(x, y);
  f2(x);
end A;
