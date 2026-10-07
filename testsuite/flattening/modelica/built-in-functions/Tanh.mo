// name: Tanh
// keywords: tanh
// status: correct
//
// Tests the built-in tanh function
//

model Tanh
  Real r;
equation
  r = tanh(45);
end Tanh;

// Result:
// class Tanh
//   Real r;
// equation
//   r = 1.0;
// end Tanh;
// endResult
