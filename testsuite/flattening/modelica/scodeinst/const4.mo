// name: const4.mo
// keywords:
// status: correct
// cflags: -d=newInst
//


class P
  constant Real i = 3;
end P;

model A
  P p[2](i = {1, 2});
  Real x[2] = p.i;
end A;

// Result:
// class A
//   constant Real p[1].i = 1.0;
//   constant Real p[2].i = 2.0;
//   Real x[1];
//   Real x[2];
// equation
//   x = {1.0, 2.0};
// end A;
// endResult
