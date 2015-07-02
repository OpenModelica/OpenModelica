encapsulated package NFInstDump

function prefixStr<T>
  input T inPrefix;
  output String outString;
algorithm
  assert(false, getInstanceName());
end prefixStr;

annotation(__OpenModelica_Interface="frontend");
end NFInstDump;
