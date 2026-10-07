// name: SampleError
// status: incorrect

model SampleError
  Real r = 1.5;
  Integer i;
equation
  when sample(r,0.1) then
    i = pre(i)+1;
  end when;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end SampleError;

// Result:
// Error processing file: SampleError.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/others/SampleError.mo:8:3-10:11:writable] Error: Function argument start=r in call to sample has variability continuous which is not a parameter expression.
// Error: Error occurred while flattening model SampleError
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
