// name: const1.mo
// keywords:
// status: correct
// cflags: -d=newInst
//


class P
  constant Integer i = 2;
end P;

model A
  constant Integer j = 3;
end A;

model B
  extends A(j = 5);
  A a(j = 4);
  P p(i = 9);

  Real x[P.i];
  Real y[j];
  Real z[a.j];
  Real w[A.j];
  Real v[p.i];
  constant Integer i = 0;
end B;

// Result:
// class B
//   constant Integer j = 5;
//   constant Integer a.j = 4;
//   constant Integer p.i = 9;
//   Real x[1];
//   Real x[2];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real y[4];
//   Real y[5];
//   Real z[1];
//   Real z[2];
//   Real z[3];
//   Real z[4];
//   Real w[1];
//   Real w[2];
//   Real w[3];
//   Real v[1];
//   Real v[2];
//   Real v[3];
//   Real v[4];
//   Real v[5];
//   Real v[6];
//   Real v[7];
//   Real v[8];
//   Real v[9];
//   constant Integer i = 0;
// end B;
// endResult
