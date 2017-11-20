// name: DuplicateElements8
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A1
  Real x = 1.0;
end A1;

model A2
  Real x = 2.0;
end A2;

model DuplicateElements8
  extends A1;
  extends A2(x = 1.0);
end DuplicateElements8;

// Result:
