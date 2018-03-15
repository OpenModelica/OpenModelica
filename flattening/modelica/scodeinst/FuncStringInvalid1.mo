// name: FuncStringInvalid1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that type checking works for the builtin String function.
//

model FuncStringInvalid1
  String s = String({1, 2, 3});
end FuncStringInvalid1;

// Result:
// Error processing file: FuncStringInvalid1.mo
// [flattening/modelica/scodeinst/FuncStringInvalid1.mo:10:3-10:31:writable] Error: Type mismatch in binding s = array(String({1, 2, 3}[$i1], 0, true) for $i1 in 1:3), expected subtype of String, got type String[3].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
