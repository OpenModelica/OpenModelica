// name: RangeTypeError1.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model RangeTypeError1
  type E = enumeration(one, two, three);
  Real x[3] = 1:"3";
end RangeTypeError1;

// Result:
// Error processing file: RangeTypeError1.mo
// [flattening/modelica/scodeinst/RangeTypeError1.mo:10:3-10:20:writable] Error: Type mismatch in range: '1' of type
//   Integer
// is not type compatible with '"3"' of type
//   String
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
