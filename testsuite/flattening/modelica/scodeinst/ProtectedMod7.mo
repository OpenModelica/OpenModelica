// name: ProtectedMod7
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  Real x = 1.0;
end A;

model ProtectedMod7
protected
  extends A(x = 2.0);
end ProtectedMod7;

// Result:
// class ProtectedMod7
//   protected Real x = 2.0;
// end ProtectedMod7;
// endResult
