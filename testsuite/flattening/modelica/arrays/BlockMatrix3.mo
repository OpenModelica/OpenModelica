// name:     BlockMatrix3
// keywords: array
// status:   incorrect
//
// Drmodelica: 7.5 Array Concatenation and Slice Operations (p. 219)
//

class BlockMatrix3
  Real[3, 3]  P = [ 1, 2, 3;
          4, 5, 6;
          7, 8, 9];
  Real[6, 6]  Q;
equation
  Q[1:3, 1:3] = P;  // OK!
  Q[1:3, 4:6] = [Q[1:3, 1:2], -Q[1:3, 3]];  // OK, correct promotion
  Q[4:6, 1:3] = [Q[1:2, 1:3], -Q[3, 1:3]];  // ERROR!
  Q[4:6, 4:6] = P;  // OK!
end BlockMatrix3;

// Result:
// Error processing file: BlockMatrix3.mo
// [flattening/modelica/arrays/BlockMatrix3.mo:9:3-11:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/BlockMatrix3.mo:12:3-12:16:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/BlockMatrix3.mo:14:3-14:18:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/arrays/BlockMatrix3.mo:16:3-16:42:writable] Error: Type mismatch for positional argument 2 in cat(arg=Q[{1, 2}, {1, 2, 3}]). The argument has type:
//   Real[2, 3]
// expected type:
//   Real[3, :]
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
