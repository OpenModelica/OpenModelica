// name: DeclarationEquation2
// keywords: equation, array
// status: correct
//
// Tests declaration equations with vectors
//

model DeclarationEquation2
  Real x[2] = {1,2};
end DeclarationEquation2;

// Result:
// class DeclarationEquation2
//   Real x[1];
//   Real x[2];
// equation
//   x = {1.0, 2.0};
// end DeclarationEquation2;
// endResult
