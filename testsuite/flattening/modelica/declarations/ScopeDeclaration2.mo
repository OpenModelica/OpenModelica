// name:     ScopeDeclaration2
// keywords: scoping,declaration
// status:   incorrect
//
// An element is visible in its entire scope.
// The following is thus incorrect since the minimum
// value is not a parameter-expression.

class ScopeDeclaration2
  constant Real a = 3.0;
  class B
    Real a(min = a);
  end B;
  B b;
end ScopeDeclaration2;

// Result:
// Error processing file: ScopeDeclaration2.mo
// [flattening/modelica/declarations/ScopeDeclaration2.mo:12:5-12:20:writable] Error: Variable b.a: Component min of variability PARAM has binding b.a of higher variability VAR.
// Error: Error occurred while flattening model ScopeDeclaration2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
