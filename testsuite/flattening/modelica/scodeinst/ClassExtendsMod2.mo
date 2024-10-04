// name: ClassExtendsMod2
// keywords:
// status: correct
//

model A
  replaceable model C
    Real x;
  end C;
end A;

model B
  extends A;

  redeclare model extends C(x = 1)
  end C;
end B;

model ClassExtendsMod2
  B.C c[2];
end ClassExtendsMod2;

// Result:
// class ClassExtendsMod2
//   Real c[1].x = 1.0;
//   Real c[2].x = 1.0;
// end ClassExtendsMod2;
// endResult
