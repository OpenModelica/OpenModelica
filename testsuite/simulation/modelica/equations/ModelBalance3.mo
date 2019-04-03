// name: ModelBalance3
// keywords: balance
// status: correct
//
// Tests an unbalanced model with too many equations
//

model ModelBalance3
  Integer x;
  Integer y;
equation
  x = 2;
  y = x + 2;
  x = y + 2;
end ModelBalance3;

// class ModelBalance3
// Integer x;
// Integer y;
// equation
//   x = 2;
//   y = 2 + x;
//   x = 2 + y;
// end ModelBalance3;
