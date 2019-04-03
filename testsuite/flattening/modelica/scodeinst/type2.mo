// name: type2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


type MyReal
  extends Real(max = 1.0);
end MyReal;

type MyReal2
  extends MyReal(min = 1.0);
end MyReal2;

model M
  MyReal2 m(start = 1.0);
end M;

// Result:
// class M
//   Real m(min = 1.0, max = 1.0, start = 1.0);
// end M;
// endResult
