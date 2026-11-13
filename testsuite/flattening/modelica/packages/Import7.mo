// name:     Import7
// keywords: import
// status:   correct
//
// Import of constants in packages.

model Import7
  import sinx = sin;
  constant Real x = sinx(0);
end Import7;

// Result:
// class Import7
//   constant Real x = 0.0;
// end Import7;
// endResult
