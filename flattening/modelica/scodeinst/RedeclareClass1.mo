// name: RedeclareClass1.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable model B
    Real x;
  end B;

  B b;
end A;

model RedeclareClass1
  model C
    Real x = 1.0;
  end C;

  A a(redeclare model B = C);
end RedeclareClass1;


// Result:
// class RedeclareClass1
//   Real a.b.x = 1.0;
// end RedeclareClass1;
// endResult
