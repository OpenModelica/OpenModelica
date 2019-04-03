// name: ModClass5
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable model B
    Real x;
    Real y;
  end B;

  B b(y = 2.0);
end A;

model ModClass5
  model D
    Real x = 1.0;
    Real y;
  end D;

  A a1(redeclare model B = D);
  A a2;
end ModClass5;

// Result:
// class ModClass5
//   Real a1.b.x = 1.0;
//   Real a1.b.y = 2.0;
//   Real a2.b.x;
//   Real a2.b.y = 2.0;
// end ModClass5;
// endResult
