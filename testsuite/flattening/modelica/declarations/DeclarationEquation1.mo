// name: DeclarationEquation1
// keywords: equation
// status: correct
//
// Tests declaration equations with scalars
//

model DeclarationEquation1
  Real x = 1;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end DeclarationEquation1;

// Result:
// class DeclarationEquation1
//   Real x = 1.0;
// end DeclarationEquation1;
// endResult
