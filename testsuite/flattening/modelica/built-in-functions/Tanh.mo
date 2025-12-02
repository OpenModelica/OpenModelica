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
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Tanh;

// Result:
// class Tanh
//   Real r;
// equation
//   r = 1.0;
// end Tanh;
// endResult
