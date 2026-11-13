// name: DeclarationEquation3
// keywords: equation, array
// status: correct
//
// Tests declaration equations with matrices
//

model DeclarationEquation3
  Real x[2,2] = [1,2; 3,4];
end DeclarationEquation3;

// Result:
// class DeclarationEquation3
//   Real x[1,1];
//   Real x[1,2];
//   Real x[2,1];
//   Real x[2,2];
// equation
//   x = {{1.0, 2.0}, {3.0, 4.0}};
// end DeclarationEquation3;
// endResult
