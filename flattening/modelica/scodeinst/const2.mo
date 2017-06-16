// name: const2.mo
// keywords:
// status: correct
// cflags: -d=newInst
//


model A
  package P
    constant Integer i = 2;
  end P;

  Real x[P.i];
end A;

// Result:
// class A
//   Real x[1];
//   Real x[2];
// end A;
// endResult
