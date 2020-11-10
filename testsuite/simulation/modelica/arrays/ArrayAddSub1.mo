// name:     ArrayAddSub1
// keywords: array
// status:   correct
//
// Addition and substraction ops applied on arrays
// Drmodelica: 7.6 Arithmetic Array Operators (p. 223)
// cflags: -d=-newInst
//

class AddSub1
  Real Add3[2, 2] = {{1, 1}, {2, 2}} + {{1, 2}, {3, 4}};
                                      // Result: {{2, 3}, {5, 6}}
  Real Sub1[3] = {1, 2, 3} - {1, 2, 0};    // Result: {0, 0, 3}
end AddSub1;

// class AddSub1
// Real Add3[1,1];
// Real Add3[1,2];
// Real Add3[2,1];
// Real Add3[2,2];
// Real Sub1[1];
// Real Sub1[2];
// Real Sub1[3];
// equation
//   Add3[1,1] = 2.0;
//   Add3[1,2] = 3.0;
//   Add3[2,1] = 5.0;
//   Add3[2,2] = 6.0;
//   Sub1[1] = 0.0;
//   Sub1[2] = 0.0;
//   Sub1[3] = 3.0;
// end AddSub1;
