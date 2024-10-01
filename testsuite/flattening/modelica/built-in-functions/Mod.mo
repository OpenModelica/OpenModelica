// name: Mod
// keywords: mod
// status: correct
//
// Tests the built-in mod function
//

model Mod
  Real r;
equation
  r = mod(8, 3);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Mod;

// Result:
// class Mod
//   Real r;
// equation
//   r = 2.0;
// end Mod;
// endResult
