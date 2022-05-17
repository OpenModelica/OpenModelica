// name: PackageRestriction3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

package P
  function f
    input Real x;
  end f;

  constant Real x;
algorithm
  f(x);
end P;

model PackageRestriction3
  Real x = P.x;
end PackageRestriction3;

// Result:
// Error processing file: PackageRestriction3.mo
// [flattening/modelica/declarations/PackageRestriction3.mo:14:3-14:7:writable] Error: Algorithm sections are not allowed in package.
// [flattening/modelica/declarations/PackageRestriction3.mo:18:3-18:15:writable] Error: Variable P.x not found in scope PackageRestriction3.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
