// name: inst2.mo
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

model C
  extends A;

  redeclare model B
    Real y;
  end B;
end C;

// Result:
// class C
//   Real b.y;
// end C;
// endResult
