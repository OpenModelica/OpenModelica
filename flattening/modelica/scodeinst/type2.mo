// name: type2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


type MyReal
  extends Real;
end MyReal;

type MyReal2
  extends MyReal;
end MyReal2;

model M
  MyReal2 m(start = 1.0);
end M;

// Result:
// class M
//   Real m(start = 1.0);
// end M;
// endResult
