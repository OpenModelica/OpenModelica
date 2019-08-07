encapsulated package NFInstDump

function prefixStr<T>
  input T inPrefix;
  output String outString;
algorithm
  assert(false, getInstanceName());
end prefixStr;

function dumpUntypedComponentDims<T>
  input T inComponent;
  output String outString;
algorithm
  assert(false, getInstanceName());
end dumpUntypedComponentDims;

annotation(__OpenModelica_Interface="frontend");
end NFInstDump;
