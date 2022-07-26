// name: PackageRestriction2
// keywords:
// status: incorrect
// cflags: -d=newInst
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
// [flattening/modelica/declarations/PackageRestriction2.mo:14:3-14:7:writable] Error: Equations are not allowed in package.
// [flattening/modelica/declarations/PackageRestriction2.mo:18:3-18:15:writable] Error: Variable P.x not found in scope PackageRestriction2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
