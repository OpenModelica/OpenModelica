// name: IllegalSubscript
// status: correct
// Should fail in backend; not frontend

class IllegalSubscript
  Real r[1];
equation
  r[0] = 1.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end IllegalSubscript;

// Result:
// class IllegalSubscript
//   Real r[1];
// equation
//   r[0] = 1.0;
// end IllegalSubscript;
// endResult
