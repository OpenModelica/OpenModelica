// name: ClassExtends1.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that a proper error message is given when no inherited element is found for a class extends.
//

model ClassExtendsMissing1
  redeclare model extends B
    Real y = 2.0;
  end B;

  B b;
end ClassExtendsMissing1;

// Result:
// Error processing file: ClassExtendsMissing1.mo
// [flattening/modelica/scodeinst/ClassExtendsMissing1.mo:10:13-12:8:writable] Error: Base class targeted by class extends B not found in the inherited classes.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
