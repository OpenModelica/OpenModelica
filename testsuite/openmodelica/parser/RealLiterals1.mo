// name: RealLiterals1
// keywords:
// status: correct
// cflags: -d=-newInst
//
//

model RealLiterals1
  Real x_min1 = -4.940656458412465e-324;
  Real x_min2 = 4.940656458412465e-324;
  Real x_underflow1 = -4.9e-325;
  Real x_underflow2 = 4.9e-325;
end RealLiterals1;

// Result:
// [openmodelica/parser/RealLiterals1.mo:11:24-11:32:writable] Warning: Underflow: 4.9e-325 cannot be represented by a double on this machine. It will be converted to 0.0.
// [openmodelica/parser/RealLiterals1.mo:12:23-12:31:writable] Warning: Underflow: 4.9e-325 cannot be represented by a double on this machine. It will be converted to 0.0.
//
// class RealLiterals1
//   Real x_min1 = -4.940656458412465e-324;
//   Real x_min2 = 4.940656458412465e-324;
//   Real x_underflow1 = -0.0;
//   Real x_underflow2 = 0.0;
// end RealLiterals1;
// endResult
