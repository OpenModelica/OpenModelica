// name:     ScopeDeclaration2
// keywords: scoping,declaration
// status:   incorrect
//
// An element is visible in its entire scope.
// The following is thus incorrect since the minimum
// value is not a parameter-expression.

model ScopeDeclaration2
  constant Real a = 3.0;
  model B
    Real a(min = a);
  end B;
  B b;
end ScopeDeclaration2;

// Result:
// Error processing file: ScopeDeclaration2.mo
// [flattening/modelica/declarations/ScopeDeclaration2.mo:12:12-12:19:writable] Error: Component min of variability parameter has binding 'b.a' of higher variability continuous.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
