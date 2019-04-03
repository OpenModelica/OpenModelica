// name:     ArrayDiv
// keywords: array
// status:   correct
//
// Drmodelica: 7.6 Arithmetic Array Operators (p. 223)
//

class ArrayDiv
  Real Div1[3];
equation
  Div1 = {2, 4, 6} / 2;
end ArrayDiv;

// Result:
// class ArrayDiv
//   Real Div1[1];
//   Real Div1[2];
//   Real Div1[3];
// equation
//   Div1[1] = 1.0;
//   Div1[2] = 2.0;
//   Div1[3] = 3.0;
// end ArrayDiv;
// endResult
