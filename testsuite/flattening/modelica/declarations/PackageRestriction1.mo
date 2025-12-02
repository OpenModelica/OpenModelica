// name: PackageRestriction1
// keywords:
// status: incorrect
//

package P
  Real x;
end P;

model PackageRestriction1
  Real x = P.x;
end PackageRestriction1;

// Result:
// Error processing file: PackageRestriction1.mo
// [flattening/modelica/declarations/PackageRestriction1.mo:7:3-7:9:writable] Error: Variable x in package P is not constant.
// [flattening/modelica/declarations/PackageRestriction1.mo:11:3-11:15:writable] Error: Variable P.x not found in scope PackageRestriction1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
