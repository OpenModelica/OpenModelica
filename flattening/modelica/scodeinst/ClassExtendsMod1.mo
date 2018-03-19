// name: ClassExtendsMod1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable model B
    Real x;
    Real y;
  end B;
end A;

model ClassExtendsMod1
  extends A;

  redeclare model extends B(x = y)
    Real z;
  end B;

  B b;
end ClassExtendsMod1;

// Result:
// class ClassExtendsMod1
//   Real b.x = b.y;
//   Real b.y;
//   Real b.z;
// end ClassExtendsMod1;
// endResult
