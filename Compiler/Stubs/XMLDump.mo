encapsulated package XMLDump

function dumpBackendDAE<T>
  input T inBackendDAE;
  input Boolean addOriginalIncidenceMatrix;
  input Boolean addSolvingInfo;
  input Boolean addMathMLCode;
  input Boolean dumpResiduals;
  input Boolean dumpSolvedEquations;
algorithm
  assert(false, getInstanceName());
end dumpBackendDAE;

annotation(__OpenModelica_Interface="backend");
end XMLDump;
