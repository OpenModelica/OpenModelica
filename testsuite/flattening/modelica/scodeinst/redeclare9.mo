// name: redeclare9.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model A
  replaceable model M1
    Real x;
  end M1;

  replaceable model M2
    Real a;
  end M2;

  M1 m1_a;
  M2 m2_a;
end A;

model B
  extends A;

  redeclare model M1
    Real y;
  end M1;

  redeclare model M2 = M1;
end B;

// Result:
// class B
//   Real m1_a.y;
//   Real m2_a.y;
// end B;
// endResult
