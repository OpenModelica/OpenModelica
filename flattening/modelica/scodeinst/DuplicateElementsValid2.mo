// name: DuplicateElementsValid2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x = 1.0;
  Real z = x;
end A;

model B
  Real z = x;
  Real x = 1.0;
end B;

model C
  model D
    Real x = 1.0;
  end D;

  extends D;
  Real x = 1.0;
  Real y = x;
end C;

model DuplicateElementsValid2
  extends A;
  extends B;
  extends C;

  Real x = 1.0;
  Real y = x;
end DuplicateElementsValid2;

// Result:
// class DuplicateElementsValid2
//   Real x = 1.0;
//   Real z = x;
//   Real y = x;
// end DuplicateElementsValid2;
// endResult
