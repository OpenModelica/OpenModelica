// name: ClassExtends1.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
// Tests that basic class extends works.
//

model A
  replaceable model B
    Real x = 1.0;
  end B;

  B b;
end A;

model ClassExtends1
  extends A;

  redeclare model extends B
    Real y = 2.0;
  end B;

  B b2;
end ClassExtends1;

// Result:
// class ClassExtends1
//   Real b.x = 1.0;
//   Real b.y = 2.0;
//   Real b2.x = 1.0;
//   Real b2.y = 2.0;
// end ClassExtends1;
// endResult
