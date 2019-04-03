// name: ClassExtends6
// keywords:
// status: correct
// cflags: -d=newInst
//

model A1
  replaceable model B
    Real x;
  end B;
end A1;

model A2
  extends A1;

  redeclare replaceable model extends B
    Real y;
  end B;
end A2;

model A3
  extends A2;

  redeclare model extends B
    Real z;
  end B;
end A3;

model ClassExtends6
  A3.B a;
end ClassExtends6;

// Result:
// class ClassExtends6
//   Real a.x;
//   Real a.y;
//   Real a.z;
// end ClassExtends6;
// endResult
