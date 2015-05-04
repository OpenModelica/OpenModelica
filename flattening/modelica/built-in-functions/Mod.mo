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
end Mod;

// Result:
// class Mod
//   Real r;
// equation
//   r = 2.0;
// end Mod;
// endResult
