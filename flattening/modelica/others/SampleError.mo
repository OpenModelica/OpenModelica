// name: SampleError
// status: incorrect

model SampleError
  Real r = 1.5;
  Integer i;
equation
  when sample(r,0.1) then
    i = pre(i)+1;
  end when;
end SampleError;

// Result:
// Error processing file: SampleError.mo
// [flattening/modelica/others/SampleError.mo:8:3-10:11:writable] Error: Function argument start=r in call to sample has variability continuous which is not a parameter expression.
// Error: Error occurred while flattening model SampleError
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
