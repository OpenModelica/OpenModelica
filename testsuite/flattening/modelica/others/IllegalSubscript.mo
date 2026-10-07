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
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
