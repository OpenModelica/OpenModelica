// name: DuplicateElementsValid1
// keywords:
// status: correct
//

model A
  Real x = 1.0;
  Real z = x;
end A;

model DuplicateElementsValid1
  extends A;
  Real x = 1.0;
  Real y = x;
end DuplicateElementsValid1;

// Result:
// class DuplicateElementsValid1
//   Real x = 1.0;
//   Real z = x;
//   Real y = x;
// end DuplicateElementsValid1;
// endResult
