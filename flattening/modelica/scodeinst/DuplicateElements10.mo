// name: DuplicateElements10
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  Real x;
end A;

model B
  Real x;
end B;

model C
  extends A;
  extends B;
end C;

model DuplicateElements10
  extends A;
  extends C;
end DuplicateElements10;

// Result:
// class DuplicateElements10
//   Real x;
// end DuplicateElements10;
// endResult
