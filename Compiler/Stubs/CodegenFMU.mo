encapsulated package CodegenFMU

function importFMUModelica<A,B>
  input A in_txt;
  input B in_a_fmi;
  output A out_txt;
algorithm
  assert(false, getInstanceName());
end importFMUModelica;

annotation(__OpenModelica_Interface="backend");
end CodegenFMU;
