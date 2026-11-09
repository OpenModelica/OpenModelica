// name: PackageIllegal
// keywords: package
// status: incorrect
//
// Tests to make sure that a package cannot have non-class components
// THIS TEST SHOULD FAIL
//

package IllegalPackage

class LegalClass
  Integer i;
end LegalClass;

Integer i;

equation
  i = 1;
end IllegalPackage;

model PackageIllegal
  IllegalPackage.LegalClass lc;
equation
  lc.i = 1;
end PackageIllegal;

// Result:
// Error processing file: PackageIllegal.mo
// [flattening/modelica/packages/PackageIllegal.mo:15:1-15:10:writable] Error: Variable i in package IllegalPackage is not constant.
// [flattening/modelica/packages/PackageIllegal.mo:22:3-22:31:writable] Error: Class IllegalPackage.LegalClass not found in scope PackageIllegal.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
