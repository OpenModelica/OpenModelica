// name:     DoubleFuncDeclaration.mo
// status:   incorrect
//
// Checks that duplicate functions are detected.
//

model DoubleFuncDeclaration
  function f
    input Real x;
    output Real y = x;
  end f;

  function f
    input String x;
    output String y = x;
  end f;

  Real x = f(1.0);
end DoubleFuncDeclaration;

// Result:
// Error processing file: DoubleFuncDeclaration.mo
// [flattening/modelica/declarations/DoubleFuncDeclaration.mo:8:3-11:8:writable] Notification: From here:
// [flattening/modelica/declarations/DoubleFuncDeclaration.mo:13:3-16:8:writable] Error: An element with name f is already declared in this scope.
// Error: Error occurred while flattening model DoubleFuncDeclaration
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
