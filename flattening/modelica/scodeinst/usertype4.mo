// name: usertype4.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

type MyReal = Real;
type MyReal2 = MyReal(start = 3.0);
type MyReal3 = MyReal2(start = 4.0);

model M
  MyReal x;
  MyReal2 y;
  MyReal3 z;
end M;

// Result:
// class M
//   Real x;
//   Real y(start = 3.0);
//   Real z(start = 4.0);
// end M;
// endResult
