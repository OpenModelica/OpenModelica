// name: PackageRestriction2
// keywords:
// status: incorrect
//

package P
  function f
    input Real x;
  end f;

  constant Real x;
equation
  f(x);
end P;

model PackageRestriction2
  Real x = P.x;
end PackageRestriction2;

// Result:
// Error processing file: PackageRestriction2.mo
// [flattening/modelica/declarations/PackageRestriction2.mo:13:3-13:7:writable] Error: Equations are not allowed in package.
// [flattening/modelica/declarations/PackageRestriction2.mo:17:3-17:15:writable] Error: Variable P.x not found in scope PackageRestriction2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
