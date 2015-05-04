// name:     ArraysInitLegal
// keywords: <insert keywords here>
// status:   correct
//
// Test the public and protected access keywords
// Drmodelica: 3.2 Initialized (p. 94)
//
class ArraysInit
  Real A3[2, 2];
   // Array variable
  Real A4[2, 2](start = {{1, 0}, {0, 1}});
   // Array with explicit start value
end ArraysInit;

// Result:
// class ArraysInit
//   Real A3[1,1];
//   Real A3[1,2];
//   Real A3[2,1];
//   Real A3[2,2];
//   Real A4[1,1](start = 1.0);
//   Real A4[1,2](start = 0.0);
//   Real A4[2,1](start = 0.0);
//   Real A4[2,2](start = 1.0);
// end ArraysInit;
// endResult
