// name: classextends2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model A
  replaceable model M1
    Real x;
  end M1;

  replaceable model M2
    Real x;
  end M2;

  M1 m1_a;
  M2 m2_a;
end A;

model B
  extends A;

  model extends M1(x = 2.0)
    Real y;
  end M1;

  redeclare model extends M2(x = 3.0)
    Real y;
  end M2;

  M1 m1_b;
  M2 m2_b;
end B;

// Result:
// class B
//   Real m1_a.x;
//   Real m2_a.x = 3.0;
//   Real m2_a.y;
//   Real m1_b.x = 2.0;
//   Real m1_b.y;
//   Real m2_b.x = 3.0;
//   Real m2_b.y;
// end B;
// endResult
