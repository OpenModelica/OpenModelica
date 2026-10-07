// name:     DerivedEnumDim
// keywords: enumeration enum extends dimension
// status:   correct
//
// Tests that an enumeration can be used as dimension in a short class
// definition.
//

type E = enumeration(a, b, c);
type A = Real[E];

model DerivedEnumDim
  A a;
end DerivedEnumDim;

// Result:
// class DerivedEnumDim
//   Real a[E.a];
//   Real a[E.b];
//   Real a[E.c];
// end DerivedEnumDim;
// endResult
