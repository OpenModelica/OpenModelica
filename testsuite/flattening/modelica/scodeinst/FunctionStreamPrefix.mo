// name: FunctionStreamPrefix
// keywords:
// status: correct
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
// [flattening/modelica/scodeinst/FunctionStreamPrefix.mo:7:3-7:22:writable] Warning: Prefix 'stream' used outside connector declaration.
//
// endResult
