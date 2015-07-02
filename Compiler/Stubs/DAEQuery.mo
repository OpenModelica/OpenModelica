encapsulated package DAEQuery

function writeIncidenceMatrix<T>
  input T dlow;
  input String fileNamePrefix;
  input String flatModelicaStr;
  output String fileName;
algorithm
  assert(false, getInstanceName());
end writeIncidenceMatrix;

annotation(__OpenModelica_Interface="backend");
end DAEQuery;
