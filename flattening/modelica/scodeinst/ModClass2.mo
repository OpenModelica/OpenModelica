// name: ModClass2
// keywords:
// status: correct
// cflags: -d=newInst
//

package A
  replaceable model B
    Real x;
  end B;

  model C
    B b;
  end C;
end A;

model ModClass1
  model D
    Real x = 1.0;
  end D;

  package A2 = A(redeclare model B = D);
  A.C c1;
  A2.C c2;
  A2.C c3;
end ModClass1;

// Result:
// class ModClass1
//   Real c1.b.x;
//   Real c2.b.x = 1.0;
//   Real c3.b.x = 1.0;
// end ModClass1;
// endResult
