// name: const5.mo
// keywords:
// status: correct
// cflags: -d=newInst
//


model A
  Real x[P.n];
end A;

package P
  constant Integer n = 2;
  constant A a;
end P;

// Result:
// class P
// end P;
// endResult
