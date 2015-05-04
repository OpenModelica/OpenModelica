// name:     ArrayDivError
// keywords: array
// status:   incorrect
//
// Drmodelica: 7.6 Arithmetic Array Operators (p. 223)
//
class ArrayDivError
  Real Div1[1, 3], Div2, Div3;
equation
  Div1 = {2, 4, 6} / 2;
  // Result: {1, 2, 3}

  Div2 = 6 / {1, 2, 3};
  // Not allowed!

  Div3 = {1, 2, 3} / {1, 2, 2};
  // Not allowed!
end ArrayDivError;
