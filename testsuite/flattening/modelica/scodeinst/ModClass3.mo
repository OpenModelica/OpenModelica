// name: ModClass3
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable model B
    Real x;
  end B;

  model C
    B b;
  end C;

  C c;
end A;

model ModClass3
  model D
    Real x = 1.0;
  end D;

  A a1(redeclare model B = D);
  A a2;
end ModClass3;

// Result:
// class ModClass3
//   Real a1.c.b.x = 1.0;
//   Real a2.c.b.x;
// end ModClass3;
// endResult
