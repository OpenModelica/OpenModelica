// name: IllegalSubscript
// status: correct
// cflags: -d=-newInst
// Should fail in backend; not frontend

class IllegalSubscript
  Real r[1];
equation
  r[0] = 1.0;
end IllegalSubscript;

// Result:
// class IllegalSubscript
//   Real r[1];
// equation
//   r[0] = 1.0;
// end IllegalSubscript;
// endResult
