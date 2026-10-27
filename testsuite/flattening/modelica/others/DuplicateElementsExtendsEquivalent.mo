// name:     DuplicateElementsExtendsEquivalent
// keywords: check if duplicate elements one from extends are equivalent!
// status:   correct


package Crap
  type X = Real;
  type Y = Real;
end Crap;

model Duplicate
 Crap.X x;
end Duplicate;

model DuplicateElementsExtendsEquivalent
 extends Duplicate; // have another x
 import C=Crap;
 C.X x;
end DuplicateElementsExtendsEquivalent;

// Result:
// class DuplicateElementsExtendsEquivalent
//   Real x;
// end DuplicateElementsExtendsEquivalent;
// endResult
