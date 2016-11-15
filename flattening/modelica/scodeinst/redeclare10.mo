// name: redeclare10.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

package B
  constant Real x = 1.0;
  constant Real y = 3.0;
end B;

model C
  replaceable package A
    constant Real x = 2.0;
  end A;
end C;

model D
  extends C(redeclare package A = B);

  Real x = A.y;
end D;

// Result:
// class D
//   Real x = 3.0;
// end D;
// endResult
