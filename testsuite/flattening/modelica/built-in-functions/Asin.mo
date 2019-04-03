// name: Asin
// keywords: asin
// status: correct
//
// Tests the built-in asin function
//

model Asin
  Real r;
equation
  r = asin(0.5);
end Asin;

// Result:
// class Asin
//   Real r;
// equation
//   r = 0.5235987755982989;
// end Asin;
// endResult
