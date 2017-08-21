// name: DuplicateElements7
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that duplicate elements are detected and reported.
//

model A1
  model B
    Real x = 1.0;
  end B;

  B b;
end A1;

model A2
  model B
    Real x = 2.0;
  end B;

  B b;
end A2;

model DuplicateElements7
  extends A1;
  extends A2;
end DuplicateElements7;

// Result:
