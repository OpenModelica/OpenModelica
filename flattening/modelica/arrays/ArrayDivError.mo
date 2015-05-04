// name:     ArrayDivError
// keywords: array
// status:   incorrect
//
// Drmodelica: 7.6 Arithmetic Array Operators (p. 223)
//

class ArrayDivError
  Real Div1[1, 3], Div2, Div3;
equation
  Div1 = {2, 4, 6} / 2; // Result: {1, 2, 3}
  Div2 = 6 / {1, 2, 3}; // Not allowed!
  Div3 = {1, 2, 3} / {1, 2, 2}; // Not allowed!
end ArrayDivError;

// Result:
// Error processing file: ArrayDivError.mo
// [flattening/modelica/arrays/ArrayDivError.mo:11:3-11:23:writable] Error: Type mismatch in equation {{Div1[1,1], Div1[1,2], Div1[1,3]}}={1.0, 2.0, 3.0} of type Real[1, 3]=Real[3].
// Error: Error occurred while flattening model ArrayDivError
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
