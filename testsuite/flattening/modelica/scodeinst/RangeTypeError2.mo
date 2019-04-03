// name: RangeTypeError2.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model RangeTypeError2
  type E = enumeration(one, two, three);
  Real x[3] = 1:E.one:3;
end RangeTypeError2;

// Result:
// Error processing file: RangeTypeError2.mo
// [flattening/modelica/scodeinst/RangeTypeError2.mo:10:3-10:24:writable] Error: Type mismatch in range: '1' of type
//   Integer
// is not type compatible with 'E.one' of type
//   enumeration E(one, two, three)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
