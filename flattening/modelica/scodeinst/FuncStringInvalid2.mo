// name: FuncStringInvalid2
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that positional arguments can't be used for the named parameters in
// the String function.
//

model FuncStringInvalid2
  String s = String(1, false, 3);
end FuncStringInvalid2;

// Result:
// Error processing file: FuncStringInvalid2.mo
// [flattening/modelica/scodeinst/FuncStringInvalid2.mo:11:3-11:33:writable] Error: No matching function found for String(/*Integer*/ 1, /*Boolean*/ false, /*Integer*/ 3).
// Candidates are:
//   String(enumeration(:) $e, Integer minimumLength = 0, Boolean leftJustified = true) => String
//   String(Integer $i, Integer minimumLength = 0, Boolean leftJustified = true) => String
//   String(Boolean $b, Integer minimumLength = 0, Boolean leftJustified = true) => String
//   String(Real $r, Integer significantDigits = 6, Integer minimumLength = 0, Boolean leftJustified = true) => String
//   String(Real $r, String format) => String
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
