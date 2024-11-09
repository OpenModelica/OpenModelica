encapsulated package EXT_LLVM

function initGen<T>
  input T t;
algorithm
  assert(false, getInstanceName());
end initGen;

annotation(__OpenModelica_Interface="backend");
end EXT_LLVM;
