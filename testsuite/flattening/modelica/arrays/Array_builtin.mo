// name:     Array_builtin
// keywords: array
// status:   incorrect
//
// This is a simple test of basic array handling.
// A matrix can not be equal to an array

model Array_builtin
   Real x=1.0;
   Real y=2.0;
   Integer q;
   Integer A1[5]=[1,2,3,4,5];
   algorithm
    x:=ndims(A1);
    x:=sin(y);
end Array_builtin;

// Result:
// Error processing file: Array_builtin.mo
// [flattening/modelica/arrays/Array_builtin.mo:12:4-12:29:writable] Error: Type mismatch in binding 'A1 = cat(2, {{1}}, {{2}}, {{3}}, {{4}}, {{5}})', expected array dimensions [5], got [1, 5].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
