// name: const3.mo
// keywords:
// status: correct
// cflags: -d=newInst
//


package P
  package P1
    constant Integer i = 2;
  end P1;

  model A
    Real x[P1.i];
    Real y[P.P1.i];
  end A;
end P;

model B
  P.A a;
end B;

// Result:
// class B
//   Real a.x[1];
//   Real a.x[2];
//   Real a.y[1];
//   Real a.y[2];
// end B;
// endResult
