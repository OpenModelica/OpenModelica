// name: ProtectedMod8
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
protected
  Real x = 1.0;
end A;

model B = A(x = 2.0);

model ProtectedMod8
  B b;
end ProtectedMod8;

// Result:
// class ProtectedMod8
//   protected Real b.x = 2.0;
// end ProtectedMod8;
// endResult
