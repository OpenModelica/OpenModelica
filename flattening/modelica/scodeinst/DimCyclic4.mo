// name: DimCyclic4
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model DimCyclic4
  parameter Integer i = size(x, 2);
  Real x[i, i + 2] = {{1, 2, 3}, {4, 5, 6}};
end DimCyclic4;

// Result:
// Error processing file: DimCyclic4.mo
// [flattening/modelica/scodeinst/DimCyclic4.mo:10:3-10:44:writable] Error: Dimension 2 of x, 'i + 2', could not be evaluated due to a cyclic dependency.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
