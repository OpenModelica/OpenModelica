// name: eq5.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model A
  constant Integer j;

  model B
    model C
      model M
        constant Integer i = j;
      end M;
    end C;
  end B;

  constant B.C.M m;
end A;

model B
  A a[3](j = {1, 2, 3});
  Real x[3], y[3];
equation
  x = a.m.i .* y;
end B;


// Result:
// class B
//   constant Integer a[1].j = 1;
//   constant Integer a[1].m.i = {1, 2, 3};
//   constant Integer a[2].j = 2;
//   constant Integer a[2].m.i = {1, 2, 3};
//   constant Integer a[3].j = 3;
//   constant Integer a[3].m.i = {1, 2, 3};
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1];
//   Real y[2];
//   Real y[3];
// equation
//   x[1] = y[1];
//   x[2] = 2.0 * y[2];
//   x[3] = 3.0 * y[3];
// end B;
// endResult
