// name: inst3.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

package P
  constant Integer i = 2;

  model A
    constant Integer j = i;
  end A;
end P;

model B
  Real a[P.A.j];
end B;

// Result:
// class B
//   Real a[1];
//   Real a[2];
// end B;
// endResult
