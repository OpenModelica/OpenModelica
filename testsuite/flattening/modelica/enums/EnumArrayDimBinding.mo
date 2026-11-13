// name:     Enumeration1
// keywords: enumeration enum array
// status:   correct
//
// Checks that the enumeration dimension of the component is preserved, and not
// replaced with the dimension of the binding.
//

type E = enumeration(A, B, C);

model EnumerationArrayDimBinding
  Real x[E] = {1, 2, 3};
end EnumerationArrayDimBinding;

// Result:
// class EnumerationArrayDimBinding
//   Real x[E.A];
//   Real x[E.B];
//   Real x[E.C];
// equation
//   x = {1.0, 2.0, 3.0};
// end EnumerationArrayDimBinding;
// endResult
