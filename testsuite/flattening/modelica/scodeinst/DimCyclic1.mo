// name: DimCyclic1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model DimCyclic1
  Real x[size(x, 2), size(x, 1)] = {{1, 2, 3}, {4, 5, 6}};
end DimCyclic1;


// Result:
// Error processing file: DimCyclic1.mo
// [flattening/modelica/scodeinst/DimCyclic1.mo:8:3-8:58:writable] Error: Dimension 1 of x, 'size(x, 2)', could not be evaluated due to a cyclic dependency.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
