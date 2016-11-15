// name: redeclare8.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model A
  replaceable model M
    Real x;
  end M;

  M m;
end A;

model B
  extends A;

  redeclare model M
    Real y;
  end M;
end B;

// Result:
// class B
//   Real m.y;
// end B;
// endResult
