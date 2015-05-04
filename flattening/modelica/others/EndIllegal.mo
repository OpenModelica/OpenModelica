// name: EndIllegal
// status: incorrect

model M
  Real r = end;
end M;

// Result:
// Error processing file: EndIllegal.mo
// [flattening/modelica/others/EndIllegal.mo:5:3-5:15:writable] Error: 'end' can not be used outside array subscripts.
// Error: Error occurred while flattening model M
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
