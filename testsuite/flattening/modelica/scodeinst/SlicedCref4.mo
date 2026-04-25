// name: SlicedCref4
// keywords:
// status: incorrect
//

model SlicedCref4
  final parameter Integer a = 6;
  final parameter Integer b = 7;
  final parameter Integer c = 6;
  Real v[a, b, c];
equation
  v[2:a-1, 2:b-1, 2:b-1] = zeros(a - 2, b - 2, c - 2);
end SlicedCref4;

// Result:
// Error processing file: SlicedCref4.mo
// [flattening/modelica/scodeinst/SlicedCref4.mo:12:3-12:54:writable] Error: Type mismatch in equation v[2:a - 1, 2:b - 1, 2:b - 1] = zeros(a - 2, b - 2, c - 2) of type Real[4, 5, 5] = Integer[4, 5, 4].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
