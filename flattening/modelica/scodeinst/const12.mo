// name: const12.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Subscripted types not handled yet.
//

package A
  model M
    constant Integer i[3] = {1, 2, 3};
  end M;

  constant M m[3];
end A;

model B
  constant Integer j = A.m[1].i[2];
  Real x = j;
end B;

// Result:
//
// EXPANDED FORM:
//
// class B
//   Real x = {1,2,3};
// end B;
//
//
// Found 1 components and 0 parameters.
// class B
//   constant Integer j = 2;
//   Real x = 2.0;
// end B;
// endResult
