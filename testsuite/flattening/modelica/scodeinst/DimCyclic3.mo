// name: DimCyclic3
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model DimCyclic3
  Real x[size(x,1)] = {1, 2, 3};
end DimCyclic3;

// Result:
// Error processing file: DimCyclic3.mo
// [flattening/modelica/scodeinst/DimCyclic3.mo:9:3-9:32:writable] Error: Dimension 1 of x, 'size(x, 1)', could not be evaluated due to a cyclic dependency.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
