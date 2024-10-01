// name: RealLiterals1
// keywords:
// status: correct
//
//

model RealLiterals1
  Real x_min1 = -4.940656458412465e-324;
  Real x_min2 = 4.940656458412465e-324;
  Real x_underflow1 = -4.9e-325;
  Real x_underflow2 = 4.9e-325;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end RealLiterals1;

// Result:
// class RealLiterals1
//   Real x_min1 = -5e-324;
//   Real x_min2 = 5e-324;
//   Real x_underflow1 = -0.0;
//   Real x_underflow2 = 0.0;
// end RealLiterals1;
// [openmodelica/parser/RealLiterals1.mo:10:24-10:32:writable] Warning: Underflow: 4.9e-325 cannot be represented by a double on this machine. It will be converted to 0.0.
// [openmodelica/parser/RealLiterals1.mo:11:23-11:31:writable] Warning: Underflow: 4.9e-325 cannot be represented by a double on this machine. It will be converted to 0.0.
//
// endResult
