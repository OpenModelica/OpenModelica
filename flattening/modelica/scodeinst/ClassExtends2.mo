// name: ClassExtends2.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that class extends without redeclare works, although with a warning
// since it was deprecated in Modelica 3.4.
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

model ClassExtends2
  extends A;

  model extends M1
    Real y;
  end M1;

  redeclare model extends M2
    Real y;
  end M2;

  M1 m1_b;
  M2 m2_b;
end ClassExtends2;

// Result:
// class ClassExtends2
//   Real m1_a.x;
//   Real m1_a.y;
//   Real m2_a.x;
//   Real m2_a.y;
//   Real m1_b.x;
//   Real m1_b.y;
//   Real m2_b.x;
//   Real m2_b.y;
// end ClassExtends2;
// [flattening/modelica/scodeinst/ClassExtends2.mo:26:3-28:9:writable] Warning: Missing redeclare prefix on class extends M1, treating like redeclare anyway.
//
// endResult
