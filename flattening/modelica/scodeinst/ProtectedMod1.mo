// name: ProtectedMod1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model A
  protected Real x = 1.0;
end A;

model ProtectedMod1
  A a(x = 2.0);
end ProtectedMod1;
