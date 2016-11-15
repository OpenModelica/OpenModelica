// name: const4.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


class P
  constant Integer i = 3;
end P;

model A
  P p[2](i = {1, 2});
  Real x[2] = p.i;
end A;

// Result:
// class A
//   Real x[1] = 1.0;
//   Real x[2] = 2.0;
// end A;
// endResult
