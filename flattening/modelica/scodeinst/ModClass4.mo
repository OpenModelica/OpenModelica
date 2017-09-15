// name: ModClass4
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  model B
    replaceable model C
      Real x;
    end C;

    C c;
  end B;

  B.C c;
  B b;
end A;

model ModClass4
  model D
    Real x = 1.0;
  end D;

  A a1(B(redeclare model C = D));
  A a2;
end ModClass4;

// Result:
// class ModClass4
//   Real a1.c.x = 1.0;
//   Real a1.b.c.x = 1.0;
//   Real a2.c.x;
//   Real a2.b.c.x;
// end ModClass4;
// endResult
