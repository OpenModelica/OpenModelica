// name: RealDiv
// keywords: real, division
// status: correct
//
// tests Real division
//

model RealDiv
  constant Real r = 23424.5 / 1234.78;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end RealDiv;

// Result:
// class RealDiv
//   constant Real r = 18.970585853350396;
// end RealDiv;
// endResult
