// name: ModClass1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model A
  replaceable model B
    Real x;
  end B;

  B b;
end A;

model ModClass1
  model D
    Real x = 1.0;
  end D;

  A a1(redeclare model B = D);
  A a2;
end ModClass1;

// Result:
// class ModClass1
//   Real a1.b.x = 1.0;
//   Real a2.b.x;
// end ModClass1;
// endResult
