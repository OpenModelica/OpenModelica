// name: ModelBalance2
// keywords: balance
// status: correct
//
// Tests an unbalanced model with too few equations
//

model ModelBalance2
  Integer x;
  Integer y;
equation
  y = x + 2;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ModelBalance2;

// class ModelBalance2
// Integer x;
// Integer y;
// equation
//   y = 2 + x;
// end ModelBalance2;
