// name: FunctionStreamPrefix
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  stream input Real x;
end f;

model FunctionStreamPrefix
algorithm
  f(1.0);
end FunctionStreamPrefix;

// Result:
// class FunctionStreamPrefix
// end FunctionStreamPrefix;
// [flattening/modelica/scodeinst/FunctionStreamPrefix.mo:8:3-8:22:writable] Warning: Prefix 'stream' used outside connector declaration.
//
// endResult
