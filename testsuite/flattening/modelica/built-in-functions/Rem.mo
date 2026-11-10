// name: Rem
// keywords: rem
// status: correct
//
// Tests the built-in rem function
//

model Rem
  Real r;
equation
  r = rem(27, 6);
end Rem;

// Result:
// class Rem
//   Real r;
// equation
//   r = 3.0;
// end Rem;
// endResult
