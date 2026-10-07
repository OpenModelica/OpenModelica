// name:     Extends11
// keywords: extends
// status:   correct
//
// Testing that short-hand extend works for functions.
//

function f
output Real r = 2;
end f;

model Extends11
  function f2 = f;
  constant Real r = f2();
end Extends11;

// Result:
// class Extends11
//   constant Real r = 2.0;
// end Extends11;
// endResult
