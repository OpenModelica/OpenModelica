// name: ProtectedMod5
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  Real x = 1.0;
end A;

model B
protected
  A a;
end B;

model ProtectedMod5
  extends B(a(x = 2.0));
end ProtectedMod5;

// Result:
// class ProtectedMod5
//   protected Real a.x = 2.0;
// end ProtectedMod5;
// endResult
