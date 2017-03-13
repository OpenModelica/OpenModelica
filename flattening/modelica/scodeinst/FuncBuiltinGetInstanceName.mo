// name: FuncBuiltinGetInstanceName
// keywords: getInstanceName
// status: correct
// cflags: -d=newInst
//
// Tests the builtin getInstanceName operator.
//

model FuncBuiltinGetInstanceName
  String s = getInstanceName();
end FuncBuiltinGetInstanceName;

// Result:
// class FuncBuiltinGetInstanceName
//   String s = getInstanceName();
// end FuncBuiltinGetInstanceName;
// endResult
