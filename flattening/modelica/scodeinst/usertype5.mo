// name: usertype5.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

model MyReal
  extends Real;
end MyReal;

model M
  MyReal x;
end M;

// Result:
// class M
//   Real x;
// end M;
// endResult
