// name: EndIllegal
// status: incorrect
// cflags: -d=-newInst

model M
  Real r = end;
end M;

// Result:
// Error processing file: EndIllegal.mo
// [flattening/modelica/others/EndIllegal.mo:6:3-6:15:writable] Error: 'end' can not be used outside array subscripts.
// Error: Error occurred while flattening model M
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
