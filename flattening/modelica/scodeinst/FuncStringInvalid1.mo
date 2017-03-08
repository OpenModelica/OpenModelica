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
// [flattening/modelica/scodeinst/FuncStringInvalid1.mo:10:3-10:31:writable] Error: No matching function found for String({1, 2, 3}) in component <REMOVE ME>
// candidates are :
//   String(enumeration(:) $e, Integer minimumLength = 0, Boolean leftJustified = true) => String
//   String(Integer $i, Integer minimumLength = 0, Boolean leftJustified = true) => String
//   String(Boolean $b, Integer minimumLength = 0, Boolean leftJustified = true) => String
//   String(Real $r, Integer significantDigits = 6, Integer minimumLength = 0, Boolean leftJustified = true) => String
//   String(Real $r, String format = "-0.6g") => String
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
