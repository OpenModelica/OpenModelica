// name: redeclare10
// keywords:
// status: correct
// cflags: -d=newInst
//
//

package B
  constant Integer x = 1;
  constant Integer y = 3;
end B;

model C
  replaceable package A
    constant Integer x = 2;
  end A;
end C;

model D
  extends C(redeclare package A = B);

  Real x[A.y];
end D;

// Result:
// class D
//   Real x[1];
//   Real x[2];
//   Real x[3];
// end D;
// endResult
