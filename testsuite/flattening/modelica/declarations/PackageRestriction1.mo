// name: PackageRestriction1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

package P
  Real x;
end P;

model PackageRestriction1
  Real x = P.x;
end PackageRestriction1;

// Result:
// Error processing file: PackageRestriction1.mo
// [flattening/modelica/declarations/PackageRestriction1.mo:8:3-8:9:writable] Error: Variable x in package P is not constant.
// [flattening/modelica/declarations/PackageRestriction1.mo:12:3-12:15:writable] Error: Variable P.x not found in scope PackageRestriction1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
