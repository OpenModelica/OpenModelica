// name: usertype1.mo
// keywords:
// status: correct
//

type MyReal = Real;

model M
  MyReal x;
end M;
// Result:
// class M
//   Real x;
// end M;
// endResult
