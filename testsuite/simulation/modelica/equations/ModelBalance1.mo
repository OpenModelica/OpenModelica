// name: ModelBalance1
// keywords: balance
// status: correct
//
// Tests a balanced model
//

model ModelBalance1
  Integer x;
  Integer y;
equation
  x = 2;
  y = x + 2;
end ModelBalance1;

// class ModelBalance1
// Integer x;
// Integer y;
// equation
//   x = 2;
//   y = 2 + x;
// end ModelBalance1;
