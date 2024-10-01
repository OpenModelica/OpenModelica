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
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Rem;

// Result:
// class Rem
//   Real r;
// equation
//   r = 3.0;
// end Rem;
// endResult
