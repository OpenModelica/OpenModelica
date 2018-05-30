// name: FuncStringInvalid3
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model FuncStringInvalid3
  model A
    Real a;
  end A;

  A a;
  String s = String(a);
end FuncStringInvalid3;

// Result:
// Error processing file: FuncStringInvalid3.mo
// [flattening/modelica/scodeinst/FuncStringInvalid3.mo:14:3-14:23:writable] Error: No matching function found for String(/*A*/ a).
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
