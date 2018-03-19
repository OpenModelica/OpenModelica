// name: RedeclareElementClass2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable model C
    Real x = 1.0;
  end C;

  C b;
end A;

model B
  extends A;

  redeclare replaceable model C
    Real x = 2.0;
  end C;

  C b2;
end B;

model RedeclareElementClass2
  extends B;

  redeclare model C
    Real x = 3.0;
  end C;
end RedeclareElementClass2;

// Result:
// class RedeclareElementClass2
//   Real b.x = 3.0;
//   Real b2.x = 3.0;
// end RedeclareElementClass2;
// endResult
