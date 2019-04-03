// name: FuncStringInvalid1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that type checking works for the builtin String function.
//

model FuncStringInvalid1
  record R
    Real x;
  end R;

  R r;
  String s = String(r);
end FuncStringInvalid1;

// Result:
// Error processing file: FuncStringInvalid1.mo
// [flattening/modelica/scodeinst/FuncStringInvalid1.mo:15:3-15:23:writable] Error: No matching function found for String(/*R*/ r).
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
