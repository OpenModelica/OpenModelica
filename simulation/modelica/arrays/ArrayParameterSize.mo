model ArrayParameterSize
  parameter Integer dimN;
  Real A[dimN];
equation
  A = fill(0, dimN);
end ArrayParameterSize;

