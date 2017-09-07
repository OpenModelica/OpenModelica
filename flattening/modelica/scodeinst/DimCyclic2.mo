// name: DimCyclic2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model DimCyclic2
  Real x[size(y, 1)];
  Real y[size(x, 1)];
end DimCyclic2;


// Result:
// Error processing file: DimCyclic2.mo
// [flattening/modelica/scodeinst/DimCyclic2.mo:8:3-8:21:writable] Error: Dimension 1 of x, 'size(y, 1)', could not be evaluated due to a cyclic dependency.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
