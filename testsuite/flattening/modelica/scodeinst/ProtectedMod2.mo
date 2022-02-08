// name: ProtectedMod2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  protected Real x = 1.0;
end A;

model ProtectedMod2
  extends A(x = 2.0);
end ProtectedMod2;

// Result:
// class ProtectedMod2
//   protected Real x = 2.0;
// end ProtectedMod2;
// endResult
